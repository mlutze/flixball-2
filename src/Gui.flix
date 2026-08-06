mod Gui {
    import com.formdev.flatlaf.FlatLightLaf
    import javax.swing.Icon
    import java.util.Objects
    import java.lang.Object
    import java.awt.Component
    import javax.swing.JList
    import java.awt.LayoutManager
    import java.awt.CardLayout
    import javax.swing.SwingUtilities
    import java.awt.BasicStroke
    import java.awt.Color
    import java.awt.Graphics
    import java.awt.Graphics2D
    import java.awt.RenderingHints
    import java.awt.geom.AffineTransform
    import java.awt.geom.Arc2D$Double
    import java.awt.geom.Ellipse2D$Double
    import java.awt.geom.Line2D
    import java.awt.geom.Line2D$Double
    import java.awt.geom.Rectangle2D$Double
    import java.awt.event.ActionListener
    import java.awt.event.ActionEvent
    import javax.swing.Timer
    import javax.swing.JFrame
    import javax.swing.JPanel
    import javax.swing.JSlider
    import javax.swing.BorderFactory
    import javax.swing.JButton
    import org.dyn4j.dynamics.Body
    import org.dyn4j.dynamics.BodyFixture
    import org.dyn4j.geometry.Geometry
    import org.dyn4j.geometry.MassType
    import org.dyn4j.geometry.Vector2
    import org.dyn4j.world.World
    import java.awt.BorderLayout
    import java.awt.FlowLayout
    import javax.swing.JLabel
    import javax.swing.JCheckBox
    import javax.swing.JTextField
    import javax.swing.JComboBox
    import javax.swing.JColorChooser
    import javax.swing.BoxLayout
    import java.awt.GridLayout
    import javax.swing.DefaultListCellRenderer
    import javax.swing.SwingConstants
    import javax.swing.Box
    import java.awt.Dimension

    import java.lang.{Math => JMath}
    import java.lang.{String => JString}
    import java.lang.System

    pub def runWithGui(): Unit \ IO = {
        FlatLightLaf.setup();
        mkSetupPage()
    }

    def mkSetupPage(): Unit \ IO = {
        let mainPanel = new JFrame("Flixball 2");

        let panelIndex = Ref.fresh(Static, 0);
        let westBots = MutMap.empty(Static);
        let eastBots = MutMap.empty(Static);
        let westColor = Ref.fresh(Static, Color.RED);
        let eastColor = Ref.fresh(Static, Color.BLUE);
        let westName = Ref.fresh(Static, "West");
        let eastName = Ref.fresh(Static, "East");

        let westPanel = mkTeamPanel(westName, westColor, panelIndex, westBots, eastBots);
        let eastPanel = mkTeamPanel(eastName, eastColor, panelIndex, eastBots, westBots);

        let teamsPanel = new JPanel();
        teamsPanel.setLayout(new BoxLayout(teamsPanel, BoxLayout.X_AXIS));
        teamsPanel.add(Box.createHorizontalGlue());
        teamsPanel.add(westPanel);
        teamsPanel.add(eastPanel);
        teamsPanel.add(Box.createHorizontalGlue());

        let goButton = new JButton("Go");
        def onClickGo(_) = {
            let config = mkGameConfig(westBots, eastBots);
            let frames = Simulation.simulate(config);
            let displayConfig = {
                westTeamName = Ref.get(westName),
                westTeamColor = Ref.get(westColor),
                eastTeamName = Ref.get(eastName),
                eastTeamColor = Ref.get(eastColor)
            };
            mkSimulationPage(frames, displayConfig);
            mainPanel.dispose()

        };
        goButton.addActionListener(Utils.mkActionListener(onClickGo));

        let goPanel = new JPanel();
        goPanel.add(goButton);

        mainPanel.setSize(1200, 600);
        mainPanel.setLayout(new BorderLayout());
        mainPanel.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        mainPanel.add(teamsPanel, BorderLayout.CENTER);
        mainPanel.add(goPanel, BorderLayout.SOUTH);
        mainPanel.setLocationRelativeTo(null);
        mainPanel.setVisible(true)
    }

    def mkTeamPanel(name: Ref[String, Static], color: Ref[Color, Static], panelIndex: Ref[Int32, Static], bots: MutMap[Int32, BotLine, Static], opponents: MutMap[Int32, BotLine, Static]): JPanel \ IO = {
        let mainPanel = new JPanel(new BorderLayout());
        mainPanel.setPreferredSize(new Dimension(500, 100));
        mainPanel.setMaximumSize(new Dimension(500, Int32.maxValue()));
        let innerPanel = new JPanel();
        innerPanel.setLayout(new BoxLayout(innerPanel, BoxLayout.Y_AXIS));
        let playersPanel = makePlayersPanel(panelIndex, bots, opponents);
        let nameField = mkNameField(name);
        let colorChooser = mkColorChooser(color);
        let teamPanel = new JPanel();
        teamPanel.add(nameField);
        teamPanel.add(colorChooser);
        innerPanel.add(teamPanel);
        innerPanel.add(playersPanel);
        mainPanel.add(innerPanel, BorderLayout.NORTH);
        mainPanel
    }

    def mkNameField(name: Ref[String, Static]): JTextField \ IO = {
        let field = new JTextField(Ref.get(name), 10);
        def onChange(_) = {
            name |> Ref.put(field.getText())
        };
        field.getDocument().addDocumentListener(Utils.mkDocumentListener(onChange));
        field
    }

    def mkColorChooser(colorHolder: Ref[Color, Static]): JComboBox[(String, Color)] \ IO = {
        let options = Vector#{
            ("Magenta", Color.MAGENTA),
            ("Pink", Color.PINK),
            ("Red", Color.RED),
            ("Orange", Color.ORANGE),
            ("Yellow", Color.YELLOW),
            ("Green", Color.GREEN),
            ("Blue", Color.BLUE),
            ("Cyan", Color.CYAN),
            ("White", Color.WHITE),
            ("Light Gray", Color.LIGHT_GRAY),
            ("Gray", Color.GRAY),
            ("Dark Gray", Color.DARK_GRAY),
            ("Black", Color.BLACK)
        };
        let chooser = new JComboBox(options);

        let initial = options |> Vector.findIndexOf(match (_name, color) -> Ref.get(colorHolder).equals(color)) |> Utils.unsafeGetOpt;

        chooser.setSelectedIndex(initial);

        let renderer = new DefaultListCellRenderer {
            def getListCellRendererComponent(this: DefaultListCellRenderer, list: JList[Object], value: Object, index: Int32, isSelected: Bool, cellHasFocus: Bool): Component \ IO = {
                super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
                let (name, color) = unchecked_cast(value as (String, Color));
                this.setText(name);
                this.setIcon(mkColorIcon(color));
                checked_cast(this)
            }
        };
        chooser.setRenderer(renderer);

        def onChooseColor(_) = {
            let (_name, color) = guard(chooser.getItemAt(chooser.getSelectedIndex()));
            Ref.put(color, colorHolder)
        };
        chooser.addActionListener(Utils.mkActionListener(onChooseColor));

        chooser
    }

    def mkColorIcon(color: Color): Icon \ IO = {
        let diameter = 8;
        new Icon {
            def getIconWidth(_this: Icon): Int32 = diameter + 2
            def getIconHeight(_this: Icon): Int32 = diameter + 2
            def paintIcon(_this: Icon, _comp: Component, g: Graphics, x: Int32, y: Int32): Unit \ IO = {
                let g2 = unchecked_cast(g as Graphics2D);
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                let xf = Int32.toFloat64(x);
                let yf = Int32.toFloat64(y);
                let df = Int32.toFloat64(diameter);
                // 1 pixel of padding for stroke width
                let shape = new Ellipse2D$Double(xf + 1.0, yf + 1.0, df, df);
                g2.setColor(color);
                g2.fill(shape);
                g2.setColor(Color.BLACK);
                g2.draw(shape)
            }
        }
    }

    // remove when fixed: https://github.com/flix/flix/issues/12970
    def guard(x: a): a = {
        unchecked_cast(unchecked_cast(x as Object) as a)
    }

    def validate(eastBots: MutMap[Int32, BotLine, Static], westBots: MutMap[Int32, BotLine, Static]): Bool \ IO = {
        let allBots = MutMap.toMap(eastBots) `Map.union` MutMap.toMap(westBots);
        let names = allBots |> Map.valuesOf |> List.map(line -> line#nameField.getText());
        let duplicates = names
            |> List.frequency
            |> Map.toList
            |> List.filter(match (_name, count) -> count > 1)
            |> List.map(match (name, _count) -> name)
            |> List.toSet;
        
        foreach (
            (_id, bot) <- allBots
        ) {
            let name = bot#nameField.getText();
            if (Set.memberOf(name, duplicates)) {
                bot#nameField.setBackground(Color.PINK)
            } else {
                bot#nameField.setBackground(Color.WHITE)
            }
        };

        Set.isEmpty(duplicates)
    }

    def makePlayersPanel(panelIndex: Ref[Int32, Static], bots: MutMap[Int32, BotLine, Static], otherBots: MutMap[Int32, BotLine, Static]): JPanel \ IO = {
        let panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        let addPlayerButton = new JButton("Add Player");
        panel.add(addPlayerButton);

        def onClickAddPlayer(_): Unit \ IO = {
            run {
                addBotLine(bots, panel, otherBots);
                panel.revalidate();
                panel.repaint()
            } with GenSym.runWithRef(panelIndex)
        };
        addPlayerButton.addActionListener(Utils.mkActionListener(onClickAddPlayer));

        panel
    }

    type alias BotLine = {
        nameField = JTextField,
        botBox = JComboBox[String],
        removeButton = JButton,
        linePanel = JPanel,
        id = Int32
    }

    pub def addBotLine(botList: MutMap[Int32, BotLine, Static], botPanel: JPanel, otherBots: MutMap[Int32, BotLine, Static]): Unit \ IO + GenSym = {
        let numBots = MutMap.size(botList) + MutMap.size(otherBots);
        let botName = "Player ${numBots + 1}";
        let id = GenSym.next();
        let panel = new JPanel();
        let nameBox = new JTextField(botName, 10);
        let botNames = Map.keysOf(Bots.bots()) |> Set.toVector;
        let botBox = new JComboBox(botNames);
        let removeButton = new JButton("Remove");
        panel.add(nameBox);
        panel.add(botBox);
        panel.add(removeButton);

        def onClickRemove(_) = {
            botList |> MutMap.remove(id);
            botPanel.remove(panel);
            botPanel.revalidate();
            botPanel.repaint()
        };
        removeButton.addActionListener(Utils.mkActionListener(onClickRemove));

        def onChangeName(_) = {
            discard validate(botList, otherBots) // TODO use result
        };
        nameBox.getDocument().addDocumentListener(Utils.mkDocumentListener(onChangeName));

        botList |> MutMap.put(id, {
            id = id,
            nameField = nameBox,
            botBox = botBox,
            removeButton = removeButton,
            linePanel = panel 
        });
        let index = botPanel.getComponentCount() - 1;
        discard botPanel.add(panel, index)
    }

    def mkGameConfig(westPlayers: MutMap[Int32, BotLine, Static], eastPlayers: MutMap[Int32, BotLine, Static]): GameConfig \ IO = {
        westPlayers = westPlayers |> MutMap.valuesOf |> List.map(mkPlayer) |> List.toMap,
        eastPlayers = eastPlayers |> MutMap.valuesOf |> List.map(mkPlayer) |> List.toMap
    }

    def mkPlayer(line: BotLine): (String, Bot) \ IO = {
        let name = line#nameField.getText();
        let botName = line#botBox |> getSelectedItem;
        let bot = Bots.bots() |> Utils.unsafeGetMap(botName);
        (name, bot) 
    }

    def getSelectedItem(box: JComboBox[a]): a \ IO = {
        unchecked_cast(box.getSelectedItem() as a)
    }

    pub def mkSimulationPage(frames: Vector[Frame], config: DisplayConfig): Unit \ IO = {
        let updatingSlider = Guard.fresh(Static);
        let anchor = Ref.fresh(Static, { frame = 0, epoch = Epoch.Absolute, rate = 0, numFrames = Vector.length(frames) });

        let scorePanel = new JPanel();
        let timeLabel = new JLabel();
        timeLabel.setText("0.0");
        
        let westScoreLabel = new JLabel();
        westScoreLabel.setHorizontalTextPosition(SwingConstants.RIGHT);
        westScoreLabel.setText("0");
        westScoreLabel.setIcon(mkColorIcon(config#westTeamColor));
        let eastScoreLabel = new JLabel();
        eastScoreLabel.setHorizontalTextPosition(SwingConstants.LEFT);
        eastScoreLabel.setIcon(mkColorIcon(config#eastTeamColor));
        eastScoreLabel.setText("0");

        scorePanel.add(westScoreLabel);
        scorePanel.add(timeLabel);
        scorePanel.add(eastScoreLabel);

        let forcesRef = Ref.fresh(Static, false);

        let pitchPanel = new JPanel {
            def paintComponent(this: JPanel, g: Graphics): Unit \ IO = {
                // super.paintComponent(g);
                let g2 = unchecked_cast(g as Graphics2D);
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                let scale = Float64.min(
                    Int32.toFloat64(this.getWidth()) / (Constants.pitchLength() + 10.0),
                    Int32.toFloat64(this.getHeight()) / (Constants.pitchWidth() + 10.0)
                );
                g2.translate(
                    Int32.toFloat64(this.getWidth()) / 2.0,
                    Int32.toFloat64(this.getHeight()) / 2.0
                );
                g2.scale(scale, -scale);
                g2.setStroke(new BasicStroke(0.05f32));

                let idx = getCurrentFrame(Ref.get(anchor));
                let frame = Vector.get(idx, frames);
                let pitch = frame#pitch;
                let metadata = frame#metadata;
                let dirs = if (Ref.get(forcesRef)) {
                    Some(metadata#forces)
                } else {
                    None
                };
                Rendering.renderPitch(g2, pitch, config, dirs)
            }
        };

        let display = {
            pitch = pitchPanel,
            time = timeLabel,
            westScore = westScoreLabel,
            eastScore = eastScoreLabel
        };

        let lowerPanel = new JPanel();
        let slider = new JSlider(0, Vector.length(frames) - 1, 0);
        slider.setBorder(BorderFactory.createEmptyBorder(8, 8, 8, 8));

        let buttonPanel = new JPanel();
        let beginningButton    = new JButton("⏮︎");
        let fastBackwardButton = new JButton("⏪︎");
        let startButton        = new JButton("▶︎");
        let fastForwardButton  = new JButton("⏩︎");
        let endButton          = new JButton("⏭︎");
        let forcesButton = new JButton("Show Forces");

        buttonPanel.add(beginningButton);
        buttonPanel.add(fastBackwardButton);
        buttonPanel.add(startButton);
        buttonPanel.add(fastForwardButton);
        buttonPanel.add(endButton);
        buttonPanel.add(Box.createHorizontalStrut(10));
        buttonPanel.add(forcesButton);

        let gameLoop = makeGameLoop(frames, anchor, display, slider, updatingSlider);

        def onChangeSlider(_): Unit \ IO = {
            // ignore if we're advancing it
            updatingSlider |> Guard.ifOpen(
                () ->
                    let value = syncFromSlider(anchor, slider);
                    let frame = Vector.get(value, frames);
                    refreshDisplay(frame, display)
            )
        };

        slider.addChangeListener(Utils.mkChangeListener(onChangeSlider));


        def onClickBeginning(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () -> {
                    let value = 0;
                    setAnchor(value, anchor);
                    discard syncToSlider(anchor, slider);
                    let frame = Vector.get(value, frames);
                    refreshDisplay(frame, display)
                }
            )
        };

        beginningButton.addActionListener(Utils.mkActionListener(onClickBeginning));


        def onClickFastBackward(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let oldRate = Ref.get(anchor)#rate;
                    let newRate = Int32.min(-2, oldRate * 2);
                    discard syncToSlider(anchor, slider);
                    gameLoop.start();
                    unpauseAnchor(newRate, anchor)
            )
        };

        fastBackwardButton.addActionListener(Utils.mkActionListener(onClickFastBackward));


        def onClickStartPause(_): Unit = {
            if (gameLoop.isRunning()) {
                startButton.setText("▶︎");
                gameLoop.stop();
                pauseAnchor(anchor)
            } else {
                startButton.setText("⏸︎");
                gameLoop.start();
                unpauseAnchor(1, anchor)
            }
        };

        startButton.addActionListener(Utils.mkActionListener(onClickStartPause));

        def onClickFastForward(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let oldRate = Ref.get(anchor)#rate;
                    let newRate = Int32.max(2, oldRate * 2);
                    discard syncToSlider(anchor, slider);
                    gameLoop.start();
                    unpauseAnchor(newRate, anchor)
            )
        };

        fastForwardButton.addActionListener(Utils.mkActionListener(onClickFastForward));

        def onClickEnd(_): Unit = {
            updatingSlider |> Guard.withGuard(
                () ->
                    let value = Vector.length(frames) - 1;
                    setAnchor(value, anchor);
                    discard syncToSlider(anchor, slider);
                    let frame = Vector.get(value, frames);
                    refreshDisplay(frame, display)
            )
        };

        def onClickForces(_): Unit = {
            let nowShowing = Ref.get(forcesRef);
            if (nowShowing) {
                Ref.put(false, forcesRef);
                forcesButton.setText("Show Forces");
                pitchPanel.repaint()
            } else {
                Ref.put(true, forcesRef);
                forcesButton.setText("Hide Forces");
                pitchPanel.repaint()
            }
        };

        endButton.addActionListener(Utils.mkActionListener(onClickEnd));

        forcesButton.addActionListener(Utils.mkActionListener(onClickForces));

        lowerPanel.setLayout(new BorderLayout(0, 0));
        lowerPanel.add(slider, BorderLayout.NORTH);
        lowerPanel.add(buttonPanel, BorderLayout.SOUTH);

        let title = "${config#westTeamName} vs. ${config#eastTeamName}";
        let mainPanel = new JFrame(title);
        mainPanel.setLayout(new BorderLayout(0, 0));
        mainPanel.add(pitchPanel, BorderLayout.CENTER);
        mainPanel.add(scorePanel, BorderLayout.NORTH);
        mainPanel.add(lowerPanel, BorderLayout.SOUTH);
        mainPanel.setSize(500, 300);
        mainPanel.setExtendedState(JFrame.MAXIMIZED_BOTH);
        mainPanel.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        mainPanel.setVisible(true)
    }

    def syncToSlider(anchor: Ref[Anchor, Static], slider: JSlider): Int32 \ IO = {
        let value = getCurrentFrame(Ref.get(anchor));
        slider.setValue(value);
        value
    }

    def setAnchor(value: Int32, anchor: Ref[Anchor, Static]): Unit \ IO = {
        let epoch = Epoch.Relative(System.currentTimeMillis());
        let numFrames = Ref.get(anchor)#numFrames;
        let rate = Ref.get(anchor)#rate;
        Ref.put({ frame = value, epoch = epoch, rate = rate, numFrames = numFrames }, anchor)
    }

    def syncFromSlider(anchor: Ref[Anchor, Static], slider: JSlider): Int32 \ IO = {
        let value = slider.getValue();
        let epoch = match Ref.get(anchor)#epoch {
            case Epoch.Absolute => Epoch.Absolute
            case Epoch.Relative(_) => Epoch.Relative(System.currentTimeMillis())
        };
        let rate = Ref.get(anchor)#rate;
        let numFrames = Ref.get(anchor)#numFrames;
        Ref.put({ frame = value, epoch = epoch, rate = rate, numFrames = numFrames }, anchor);
        value
    }

    type alias Display = {
        pitch = JPanel,
        time = JLabel,
        westScore = JLabel,
        eastScore = JLabel
    }

    def refreshDisplay(
        frame: Frame,
        display: Display
    ): Unit \ IO = {
        display#pitch.repaint();
        display#time.setText(formatTimeMs(frame#pitch#timeMs));
        display#westScore.setText("${frame#pitch#westScore}");
        display#eastScore.setText("${frame#pitch#eastScore}")
    }

    type alias Anchor = {
        frame = Int32,
        epoch = Epoch,
        rate = Int32,
        numFrames = Int32
    }

    enum Epoch {
        case Absolute
        case Relative(Int64)
    }

    def pauseAnchor(anchor: Ref[Anchor, Static]): Unit \ IO = {
        let frame = getCurrentFrame(Ref.get(anchor));
        let numFrames = Ref.get(anchor)#numFrames;
        let rate = 0;
        Ref.put({ frame = frame, epoch = Epoch.Absolute, rate = rate, numFrames = numFrames }, anchor)
    }

    def unpauseAnchor(rate: Int32, anchor: Ref[Anchor, Static]): Unit \ IO = {
        let frame = getCurrentFrame(Ref.get(anchor));
        let numFrames = Ref.get(anchor)#numFrames;
        let epoch = Epoch.Relative(System.currentTimeMillis());
        Ref.put({ frame = frame, epoch = epoch, rate = rate, numFrames = numFrames }, anchor)
    }

    def getCurrentFrame(anchor: Anchor): Int32 \ IO = {
        let now = System.currentTimeMillis();
        let diff = match anchor#epoch {
            case Epoch.Absolute => 0i64
            case Epoch.Relative(time) => now - time
        };
        let physicsFrameRate = Int32.toInt64(Constants.frameRate());
        let playbackSpeed = Int32.toInt64(anchor#rate);
        let framesPassed = Int64.truncateToInt32(physicsFrameRate * diff * playbackSpeed / 1000i64);
        let desiredFrame = anchor#frame + framesPassed;
        desiredFrame |> Int32.max(0) |> Int32.min(anchor#numFrames - 1)
    }

    def makeGameLoop(
        frames: Vector[Frame],
        anchor: Ref[Anchor, Static],
        display: Display,
        slider: JSlider,
        updatingSlider: Guard[Static]
    ): Timer \ IO = {
        let deltaTs  = 1.0 / Int32.toFloat64(Constants.frameRate());
        let deltaTms = Float64.truncateToInt32(deltaTs * 1000.0);

        def onTick(event: ActionEvent) = {
            // skip if the user is scrubbing
            if (not slider.getValueIsAdjusting()) {
                let i = getCurrentFrame(Ref.get(anchor));
                if (i >= Vector.length(frames)) {
                    // reached the end of the precomputed history: stop playback
                    let timer = unchecked_cast(event.getSource() as Timer);
                    timer.stop()
                } else {
                    updatingSlider |> Guard.withGuard(
                        () ->
                            slider.setValue(i)
                    );
                    let frame = Vector.get(i, frames);
                    refreshDisplay(frame, display)
                }
            }
        };

        new Timer(deltaTms, Utils.mkActionListener(onTick))
    }

    def formatTimeMs(ms: Int32): String = {
        let s = Int32.toFloat64(ms) / 1000.0;
        unsafe IO { JString.format("%.1f", Float64.valueOf(s)) }
    }

}