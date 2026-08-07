mod Utils {
    import org.dyn4j.world.BroadphaseCollisionData
    import org.dyn4j.world.listener.CollisionListenerAdapter
    import org.dyn4j.world.listener.CollisionListener
    import java.awt.color.ColorSpace
    import java.awt.Color
    import java.awt.event.ActionEvent
    import java.awt.event.ActionListener
    import java.lang.Runnable
    import java.util.TimerTask
    import javax.swing.event.ChangeEvent
    import javax.swing.event.ChangeListener
    import javax.swing.event.DocumentEvent
    import javax.swing.event.DocumentListener

    import org.dyn4j.dynamics.Body

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

    pub def mkDocumentListener(f: DocumentEvent -> Unit \ ef): DocumentListener \ IO = {
        new DocumentListener {
            def changedUpdate(_this: DocumentListener, e: DocumentEvent): Unit \ ef = f(e)
            def insertUpdate(_this: DocumentListener, e: DocumentEvent): Unit \ ef = f(e)
            def removeUpdate(_this: DocumentListener, e: DocumentEvent): Unit \ ef = f(e)
        }
    }

    pub def mkCollisionListener(f: (Body, Body) -> Unit \ ef): CollisionListener[Body, Body] \ IO = {
        let adapter = new CollisionListenerAdapter[Body, Body] {
            def collision(_this: CollisionListenerAdapter[Body, Body], data: BroadphaseCollisionData[Body, Body]): Bool \ IO + ef = {
                let b1 = data.getBody1();
                let b2 = data.getBody2();
                f(b1, b2);
                true
            }
        };
        checked_cast(adapter)
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

    // https://stackoverflow.com/questions/596216/formula-to-determine-perceived-brightness-of-rgb-color
    pub def getRelLuminance(c: Color): Float64 = {
        unsafe IO {
            def toFraction(i) = Int32.toFloat64(i) / 255.0f64;

            def linearize(f) = {
                if (f <= 0.04045) {
                    f / 12.92
                } else {
                    Float64.pow(base = (f + 0.055) / 1.055, 2.4)
                }
            };

            let r  = c.getRed() |> toFraction |> linearize;
            let g  = c.getGreen() |> toFraction |> linearize;
            let b  = c.getBlue() |> toFraction |> linearize;

            0.2126 * r + 0.7152 * g + 0.0722 * b
        }
    }

    pub def contrast(c1: Color, c2: Color): Float64 = {
        let lum1 = getRelLuminance(c1);
        let lum2 = getRelLuminance(c2);

        let lighter = Float64.max(lum1, lum2);
        let darker = Float64.min(lum1, lum2);

        (lighter + 0.05) / (darker + 0.05)
    }

    pub def textColorForBackground(c: Color): Color = {
        let whiteContrast = contrast(c, Color.WHITE);
        let blackContrast = contrast(c, Color.BLACK);

        if (whiteContrast > blackContrast) {
            Color.WHITE
        } else {
            Color.BLACK
        }
    }
}