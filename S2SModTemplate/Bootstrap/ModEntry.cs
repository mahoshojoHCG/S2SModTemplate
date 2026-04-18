using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using S2SModTemplate.Diagnostics;
using System.Runtime.InteropServices;

namespace S2SModTemplate.Bootstrap;

[ModInitializer(nameof(Initialize))]
public static class ModEntry
{
    private const string HarmonyId = "sts2.s2smodtemplate";
    private const int RtldNow = 2;
    private const int RtldGlobal = 0x100;
    private static int _initialized;

    public static void Initialize()
    {
        if (Interlocked.Exchange(ref _initialized, 1) != 0)
        {
            return;
        }

        try
        {
            TemplateLog.Info("Bootstrap starting.");
            EnsureHarmonyNativeDependencies();

            var harmony = new Harmony(HarmonyId);
            harmony.PatchAll(typeof(ModEntry).Assembly);

            TemplateLog.Info("Bootstrap completed.");
        }
        catch (Exception ex)
        {
            TemplateLog.Error("Bootstrap failed.", ex);
        }
    }

    private static void EnsureHarmonyNativeDependencies()
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            return;
        }

        PreloadLinuxNativeLibrary("libgcc_s.so.1", "/usr/lib/libgcc_s.so.1", "/lib64/libgcc_s.so.1", "/lib/libgcc_s.so.1");
        PreloadLinuxNativeLibrary("libunwind.so.8", "/usr/lib/libunwind.so.8", "/lib64/libunwind.so.8", "/lib/libunwind.so.8");
    }

    private static void PreloadLinuxNativeLibrary(params string[] candidates)
    {
        foreach (var candidate in candidates)
        {
            if (TryDlopenGlobal(candidate, out var handle, out var error))
            {
                TemplateLog.Info($"Preloaded native dependency: {candidate}, handle=0x{handle.ToInt64():x}");
                return;
            }

            TemplateLog.Warn($"Failed to preload native dependency: {candidate} ({error})");
        }
    }

    private static bool TryDlopenGlobal(string libraryName, out IntPtr handle, out string? error)
    {
        const string libdl = "libdl.so.2";

        handle = IntPtr.Zero;
        error = null;

        try
        {
            if (!NativeLibrary.TryLoad(libdl, out var libdlHandle))
            {
                error = $"failed to load {libdl}";
                return false;
            }

            if (!NativeLibrary.TryGetExport(libdlHandle, "dlopen", out var dlopenPtr) ||
                !NativeLibrary.TryGetExport(libdlHandle, "dlerror", out var dlerrorPtr))
            {
                error = "failed to resolve dlopen/dlerror";
                return false;
            }

            var dlopen = Marshal.GetDelegateForFunctionPointer<DlopenDelegate>(dlopenPtr);
            var dlerror = Marshal.GetDelegateForFunctionPointer<DlerrorDelegate>(dlerrorPtr);

            dlerror();
            handle = dlopen(libraryName, RtldNow | RtldGlobal);
            if (handle != IntPtr.Zero)
            {
                return true;
            }

            var errorPtr = dlerror();
            error = errorPtr == IntPtr.Zero ? "unknown dlopen error" : Marshal.PtrToStringAnsi(errorPtr);
            return false;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate IntPtr DlopenDelegate([MarshalAs(UnmanagedType.LPUTF8Str)] string fileName, int flags);

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate IntPtr DlerrorDelegate();
}
