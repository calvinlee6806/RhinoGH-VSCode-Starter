using System;
using System.Drawing;
using Grasshopper.Kernel;

namespace MyPlugin.Components
{
    // Sample component: Sum = A + B. Copy this file to add a component, and give the copy a new ComponentGuid.
    public class SumComponent : GH_Component
    {
        public SumComponent()
            : base("Sum", "Sum", "Adds two numbers.", "MyPlugin", "01 Sample")
        {
        }

        // The Guid identifies the component in saved .gh files. It must stay unchanged after the first release.
        public override Guid ComponentGuid => new Guid("00000000-0000-4000-8000-0000000000b1");

        protected override Bitmap Icon => null;

        protected override void RegisterInputParams(GH_InputParamManager pManager)
        {
            pManager.AddNumberParameter("A", "A", "First number.", GH_ParamAccess.item, 0.0);
            pManager.AddNumberParameter("B", "B", "Second number.", GH_ParamAccess.item, 0.0);
        }

        protected override void RegisterOutputParams(GH_OutputParamManager pManager)
        {
            pManager.AddNumberParameter("Sum", "S", "A + B.", GH_ParamAccess.item);
        }

        protected override void SolveInstance(IGH_DataAccess da)
        {
            double a = 0.0;
            double b = 0.0;
            if (!da.GetData(0, ref a)) return;
            if (!da.GetData(1, ref b)) return;

            da.SetData(0, a + b);
        }
    }
}
