using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using System.Runtime.InteropServices;

namespace MOD_NAMESPACE.Bootstrap;

[ModInitializer(nameof(Initialize))]
public static class ModEntry
{
    private const string HarmonyId = "MOD_HARMONY_ID";
    private static int _initialized;

    public static void Initialize()
    {
        if (Interlocked.Exchange(ref _initialized, 1) != 0)
        {
            return;
        }

        try
        {
            EnsureHarmonyNativeDependencies();

            var harmony = new Harmony(HarmonyId);
            harmony.PatchAll(typeof(ModEntry).Assembly);

            Console.WriteLine($"[{HarmonyId}] initialized");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[{HarmonyId}] initialization failed: {ex}");
        }
    }

    // Harmony's transpiler path on Linux can fail to resolve libgcc_s/libunwind
    // unless they are loaded with RTLD_GLOBAL. This preloads them via dlopen.
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
            if (TryDlopenGlobal(candidate, out _, out _))
            {
                return;
            }
        }
    }

    private static bool TryDlopenGlobal(string libraryName, out IntPtr handle, out string? error)
    {
        const int RtldNow = 2;
        const int RtldGlobal = 0x100;
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
