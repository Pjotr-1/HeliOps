using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.RegularExpressions;
using Grpc.Net.Client;
using HeliOpsBridge.Grpc;

namespace HeliOpsBridge;

internal static class Program
{
    private const int RadioPort = 9088;
    private const int CommandPort = 9089;
    private const string GrpcAddress = "http://127.0.0.1:50051";

    private static readonly TimeSpan RadioMaxAge =
        TimeSpan.FromSeconds(2);

    private static readonly HashSet<string> Commands =
        new(StringComparer.OrdinalIgnoreCase)
        {
            "TAXI",
            "TAKEOFF",
            "INBOUND",
            "DIRECT",
            "HOLDING",
            "CONFIRM_LANDING"
        };

    private static readonly Regex SafeToken =
        new("^[A-Z0-9_]+$", RegexOptions.Compiled);

    private static readonly object RadioLock = new();
    private static RadioState? _radioState;

    public static async Task<int> Main(string[] args)
    {
        if (args.Length > 0)
            return await SendCommandToResidentAsync(args);

        Console.Title = "HeliOpsBridge";
        Console.WriteLine("HeliOpsBridge");
        Console.WriteLine($"Radio UDP   : 127.0.0.1:{RadioPort}");
        Console.WriteLine($"Command UDP : 127.0.0.1:{CommandPort}");
        Console.WriteLine($"DCS-gRPC    : {GrpcAddress}");
        Console.WriteLine();

        using var channel = GrpcChannel.ForAddress(GrpcAddress);
        var grpc = new TriggerService.TriggerServiceClient(channel);

        using var cancellation = new CancellationTokenSource();

        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            cancellation.Cancel();
        };

        await Task.WhenAll(
            RunRadioReceiverAsync(cancellation.Token),
            RunCommandReceiverAsync(grpc, cancellation.Token)
        );

        return 0;
    }

    private static async Task<int> SendCommandToResidentAsync(string[] args)
    {
        if (args.Length != 2)
        {
            Console.Error.WriteLine(
                "Usage: HeliOpsBridge.exe <AIRPORT> <COMMAND>"
            );
            return 2;
        }

        var airport = NormalizeToken(args[0]);
        var command = NormalizeToken(args[1]);

        if (!IsSafeToken(airport))
        {
            Console.Error.WriteLine($"Invalid airport key '{args[0]}'.");
            return 2;
        }

        if (!Commands.Contains(command))
        {
            Console.Error.WriteLine($"Unknown command '{args[1]}'.");
            return 2;
        }

        using var udp = new UdpClient(0);

        var data = Encoding.ASCII.GetBytes($"{airport}|{command}");

        await udp.SendAsync(
            data,
            data.Length,
            "127.0.0.1",
            CommandPort
        );

        var receiveTask = udp.ReceiveAsync();
        var completed = await Task.WhenAny(
            receiveTask,
            Task.Delay(1500)
        );

        if (completed != receiveTask)
        {
            Console.Error.WriteLine(
                "Resident HeliOpsBridge is not responding."
            );
            return 3;
        }

        var response =
            Encoding.ASCII.GetString(receiveTask.Result.Buffer);

        Console.WriteLine(response);

        return response.StartsWith(
            "OK|",
            StringComparison.OrdinalIgnoreCase
        ) ? 0 : 4;
    }

    private static async Task RunRadioReceiverAsync(
        CancellationToken cancellationToken
    )
    {
        using var udp =
            new UdpClient(
                new IPEndPoint(IPAddress.Loopback, RadioPort)
            );

        Console.WriteLine("Waiting for cockpit radio state...");

        while (!cancellationToken.IsCancellationRequested)
        {
            UdpReceiveResult packet;

            try
            {
                packet = await udp.ReceiveAsync(cancellationToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var text =
                Encoding.ASCII.GetString(packet.Buffer).Trim();

            if (!TryParseRadioState(text, out var state))
                continue;

            lock (RadioLock)
                _radioState = state;
        }
    }

    private static async Task RunCommandReceiverAsync(
        TriggerService.TriggerServiceClient grpc,
        CancellationToken cancellationToken
    )
    {
        using var udp =
            new UdpClient(
                new IPEndPoint(IPAddress.Loopback, CommandPort)
            );

        while (!cancellationToken.IsCancellationRequested)
        {
            UdpReceiveResult packet;

            try
            {
                packet = await udp.ReceiveAsync(cancellationToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var text =
                Encoding.ASCII.GetString(packet.Buffer).Trim();

            var parts = text.Split('|');
            string response;

            if (parts.Length != 2)
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|BAD_COMMAND_FORMAT"
                );
                continue;
            }

            var airport = NormalizeToken(parts[0]);
            var command = NormalizeToken(parts[1]);

            if (!IsSafeToken(airport))
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|BAD_AIRPORT"
                );
                continue;
            }

            if (!Commands.Contains(command))
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|BAD_COMMAND"
                );
                continue;
            }

            RadioState? radio;
            lock (RadioLock)
                radio = _radioState;

            if (radio is null)
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|NO_RADIO_STATE"
                );
                continue;
            }

            if (DateTime.UtcNow - radio.TimestampUtc > RadioMaxAge)
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|RADIO_STATE_STALE"
                );
                continue;
            }

            if (!radio.Selected)
            {
                await ReplyAsync(
                    udp,
                    packet.RemoteEndPoint,
                    "ERR|RADIO_NOT_SELECTED"
                );
                continue;
            }

            try
            {
                await SetFlagAsync(
                    grpc,
                    "HELIOPS_RADIO_FREQ_HZ",
                    radio.FrequencyHz
                );

                await SetFlagAsync(
                    grpc,
                    "HELIOPS_RADIO_MOD",
                    radio.Modulation
                );

                var callFlag =
                    $"HELIOPS_CALL_{airport}_{command}";

                await SetFlagAsync(grpc, callFlag, 1);

                response =
                    $"OK|{airport}|{command}|" +
                    $"{radio.Aircraft}|{radio.Radio}|" +
                    $"{radio.FrequencyHz}|{radio.Modulation}";

                Console.WriteLine(
                    $"{airport} {command} -> " +
                    $"{radio.FrequencyHz / 1_000_000.0:F3} MHz"
                );
            }
            catch (Exception ex)
            {
                response =
                    "ERR|GRPC|" +
                    ex.Message
                        .Replace('|', '/')
                        .Replace('\r', ' ')
                        .Replace('\n', ' ');
            }

            await ReplyAsync(
                udp,
                packet.RemoteEndPoint,
                response
            );
        }
    }

    private static async Task SetFlagAsync(
        TriggerService.TriggerServiceClient grpc,
        string flag,
        uint value
    )
    {
        await grpc.SetUserFlagAsync(
            new SetUserFlagRequest
            {
                Flag = flag,
                Value = value
            },
            deadline: DateTime.UtcNow.AddSeconds(1)
        );
    }

    private static async Task ReplyAsync(
        UdpClient udp,
        IPEndPoint destination,
        string response
    )
    {
        var data = Encoding.ASCII.GetBytes(response);
        await udp.SendAsync(data, data.Length, destination);
    }

    private static bool TryParseRadioState(
        string text,
        out RadioState state
    )
    {
        state = default!;

        var parts = text.Split('|');
        if (parts.Length != 5) return false;

        var aircraft = NormalizeToken(parts[0]);
        var radio = NormalizeToken(parts[1]);

        if (!IsSafeToken(aircraft) || !IsSafeToken(radio))
            return false;

        if (!uint.TryParse(parts[2], out var frequencyHz))
            return false;

        if (!uint.TryParse(parts[3], out var modulation))
            return false;

        if (!uint.TryParse(parts[4], out var selected))
            return false;

        state = new RadioState(
            aircraft,
            radio,
            frequencyHz,
            modulation,
            selected != 0,
            DateTime.UtcNow
        );

        return true;
    }

    private static string NormalizeToken(string value)
    {
        return value
            .Trim()
            .ToUpperInvariant()
            .Replace('-', '_')
            .Replace(' ', '_');
    }

    private static bool IsSafeToken(string value)
    {
        return !string.IsNullOrWhiteSpace(value)
            && SafeToken.IsMatch(value);
    }

    private sealed record RadioState(
        string Aircraft,
        string Radio,
        uint FrequencyHz,
        uint Modulation,
        bool Selected,
        DateTime TimestampUtc
    );
}
