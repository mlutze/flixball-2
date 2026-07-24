
// The main entry point.
def main(): Unit \ IO = {
    let args = run Sys.Env.getArgs() with Sys.Env.runWithIO;
    if (args == List#{"-H"}) {
        Simulation.runHeadless()
    } else {
        Gui.runWithGui()
    }
}
