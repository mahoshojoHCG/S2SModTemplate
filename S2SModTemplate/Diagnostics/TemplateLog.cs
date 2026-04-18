namespace S2SModTemplate.Diagnostics;

public static class TemplateLog
{
    private static readonly object Sync = new();
    private static readonly string LogPath = Path.Combine(AppContext.BaseDirectory, "S2SModTemplate.log");

    public static void Info(string message) => Write("INFO", message);

    public static void Warn(string message) => Write("WARN", message);

    public static void Error(string message, Exception? exception = null)
    {
        var suffix = exception is null ? string.Empty : $"{Environment.NewLine}{exception}";
        Write("ERROR", $"{message}{suffix}");
    }

    private static void Write(string level, string message)
    {
        var line = $"[{DateTimeOffset.Now:yyyy-MM-dd HH:mm:ss.fff zzz}] [{level}] {message}";
        lock (Sync)
        {
            Console.WriteLine(line);

            try
            {
                File.AppendAllText(LogPath, line + Environment.NewLine);
            }
            catch
            {
                // Keep logging best-effort; console output remains the fallback.
            }
        }
    }
}
