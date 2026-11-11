// Marks the .NET 7 assembly as Windows-only, because Grasshopper and System.Drawing run on Windows.
// The .NET Framework build is Windows-only by definition.

#if NET5_0_OR_GREATER
[assembly: System.Runtime.Versioning.SupportedOSPlatform("windows")]
#endif
