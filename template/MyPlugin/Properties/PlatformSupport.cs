// Marks the .NET (Core) assemblies (net8.0, net10.0) as Windows-only, because Grasshopper and System.Drawing
// run on Windows. The .NET Framework build (net48) is Windows-only by definition.

#if NET5_0_OR_GREATER
[assembly: System.Runtime.Versioning.SupportedOSPlatform("windows")]
#endif
