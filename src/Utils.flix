mod Utils {
    import java.awt.event.ActionEvent
    import javax.swing.event.ChangeEvent
    import javax.swing.event.ChangeListener
    import java.awt.event.ActionListener
    import java.util.TimerTask
    import java.lang.Runnable

    pub def mkRunnable(f: Unit -> Unit \ ef): Runnable \ IO = {
        new Runnable {
            def $run(_this: Runnable): Unit \ ef = f()
        }
    }

    pub def mkTimerTask(f: Unit -> Unit \ ef): TimerTask \ IO = {
        new TimerTask {
            def $run(_this: TimerTask): Unit \ ef = f()
        }
    }

    pub def mkActionListener(f: ActionEvent -> Unit \ ef): ActionListener \ IO = {
        new ActionListener {
            def actionPerformed(_this: ActionListener, e: ActionEvent): Unit \ ef = f(e)
        }
    }

    pub def mkChangeListener(f: ChangeEvent -> Unit \ ef): ChangeListener \ IO = {
        new ChangeListener {
            def stateChanged(_this: ChangeListener, e: ChangeEvent): Unit \ ef = f(e)
        }
    }

    pub def unsafeGetOpt(opt: Option[a]): a = {
        match opt {
            case None => unreachable!()
            case Some(x) => x
        }
    }

    pub def unsafeGetMap(key: k, map: Map[k, v]): v with Order[k] = {
        unsafeGetOpt(Map.get(key, map))
    }

    pub def mkCmp(f: a -> b \ ef): ((a, a) -> Comparison \ ef) with Order[b] = {
        (x, y) -> f(x) <=> f(y)
    }

    pub def clampInt32(min: {min = Int32}, max: {max = Int32}, value: Int32): Int32 = {
        value |> Int32.min(max#max) |> Int32.max(min#min)
    }
}