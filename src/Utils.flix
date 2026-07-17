mod Utils {
    import java.awt.event.ActionEvent
    import java.awt.event.ActionListener
    import java.util.TimerTask
    import java.lang.Runnable
    import java.lang.Math

    pub def randomChoice(l: Vector[a]): a \ IO = {
        let idx = Float64.truncateToInt32(Math.random() * Int32.toFloat64(Vector.length(l)));
        run {
            l[idx]
        } with handler OutOfBounds {
            def outOfBounds(_, _) = unreachable!()
        }
    }

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
}