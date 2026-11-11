using System;
using System.Drawing;
using Grasshopper.Kernel;

namespace MyPlugin
{
    // Identity of the assembly in Grasshopper. The Id value must stay unchanged after the first release.
    public class MyPluginInfo : GH_AssemblyInfo
    {
        public override string Name => "MyPlugin";

        public override Bitmap Icon => null;

        public override string Description => "Grasshopper plug-in MyPlugin.";

        public override Guid Id => new Guid("00000000-0000-4000-8000-0000000000a1");

        public override string AuthorName => "";

        public override string AuthorContact => "";

        public override string AssemblyVersion => GetType().Assembly.GetName().Version.ToString();
    }
}
