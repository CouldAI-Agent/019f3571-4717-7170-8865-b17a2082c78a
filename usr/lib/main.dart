import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';

void main() {
  runApp(const AnimationMakerApp());
}

class AnimationMakerApp extends StatelessWidget {
  const AnimationMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animation Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AnimationEditorScreen(),
      },
    );
  }
}

class DrawingStroke {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class AnimationFrame {
  final List<DrawingStroke> strokes;

  AnimationFrame({required this.strokes});

  AnimationFrame copy() {
    return AnimationFrame(
      strokes: strokes.map((s) => DrawingStroke(
        points: List.from(s.points),
        color: s.color,
        strokeWidth: s.strokeWidth,
      )).toList(),
    );
  }
}

class AnimationEditorScreen extends StatefulWidget {
  const AnimationEditorScreen({super.key});

  @override
  State<AnimationEditorScreen> createState() => _AnimationEditorScreenState();
}

class _AnimationEditorScreenState extends State<AnimationEditorScreen> {
  List<AnimationFrame> frames = [AnimationFrame(strokes: [])];
  int currentFrameIndex = 0;
  bool isPlaying = false;
  Timer? playbackTimer;
  double fps = 12.0;

  Color currentBrushColor = Colors.white;
  double currentStrokeWidth = 5.0;
  List<Offset?> currentLine = [];
  
  bool showOnionSkin = true;

  @override
  void dispose() {
    playbackTimer?.cancel();
    super.dispose();
  }

  void togglePlayback() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        startPlayback();
      } else {
        stopPlayback();
      }
    });
  }

  void startPlayback() {
    playbackTimer?.cancel();
    playbackTimer = Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
      setState(() {
        currentFrameIndex = (currentFrameIndex + 1) % frames.length;
      });
    });
  }

  void stopPlayback() {
    playbackTimer?.cancel();
  }

  void addFrame() {
    setState(() {
      frames.insert(currentFrameIndex + 1, AnimationFrame(strokes: []));
      currentFrameIndex++;
    });
  }

  void duplicateFrame() {
    setState(() {
      frames.insert(currentFrameIndex + 1, frames[currentFrameIndex].copy());
      currentFrameIndex++;
    });
  }

  void deleteFrame() {
    if (frames.length > 1) {
      setState(() {
        frames.removeAt(currentFrameIndex);
        if (currentFrameIndex >= frames.length) {
          currentFrameIndex = frames.length - 1;
        }
      });
    }
  }

  void clearFrame() {
    setState(() {
      frames[currentFrameIndex].strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Maker'),
        actions: [
          IconButton(
            icon: Icon(showOnionSkin ? Icons.layers : Icons.layers_clear),
            tooltip: 'Toggle Onion Skin',
            onPressed: () {
              setState(() {
                showOnionSkin = !showOnionSkin;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Frame',
            onPressed: clearFrame,
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: togglePlayback,
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                const Text('Brush: '),
                DropdownButton<Color>(
                  value: currentBrushColor,
                  items: [
                    Colors.white,
                    Colors.black,
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.yellow,
                  ].map((c) => DropdownMenuItem(
                    value: c,
                    child: Container(width: 24, height: 24, color: c),
                  )).toList(),
                  onChanged: (c) {
                    if (c != null) {
                      setState(() {
                        currentBrushColor = c;
                      });
                    }
                  },
                ),
                const SizedBox(width: 16),
                const Text('Size: '),
                Expanded(
                  child: Slider(
                    value: currentStrokeWidth,
                    min: 1.0,
                    max: 50.0,
                    onChanged: (val) {
                      setState(() {
                        currentStrokeWidth = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Text('FPS: '),
                DropdownButton<double>(
                  value: fps,
                  items: [1.0, 5.0, 10.0, 12.0, 24.0, 30.0].map((f) => DropdownMenuItem(
                    value: f,
                    child: Text('${f.toInt()}'),
                  )).toList(),
                  onChanged: (f) {
                    if (f != null) {
                      setState(() {
                        fps = f;
                        if (isPlaying) {
                          startPlayback();
                        }
                      });
                    }
                  },
                )
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                      ]
                    ),
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (isPlaying) return;
                        setState(() {
                          currentLine = [details.localPosition];
                          frames[currentFrameIndex].strokes.add(
                            DrawingStroke(
                              points: currentLine,
                              color: currentBrushColor,
                              strokeWidth: currentStrokeWidth,
                            )
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        if (isPlaying) return;
                        setState(() {
                          currentLine.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        if (isPlaying) return;
                        setState(() {
                          currentLine.add(null); // End of stroke
                        });
                      },
                      child: ClipRect(
                        child: CustomPaint(
                          painter: AnimationPainter(
                            currentFrame: frames[currentFrameIndex],
                            previousFrame: showOnionSkin && currentFrameIndex > 0 ? frames[currentFrameIndex - 1] : null,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Timeline
          Container(
            height: 100,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: frames.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            currentFrameIndex = index;
                            if (isPlaying) togglePlayback();
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: currentFrameIndex == index ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.grey[800],
                            border: Border.all(
                              color: currentFrameIndex == index ? Theme.of(context).colorScheme.primary : Colors.grey[600]!,
                              width: 2,
                            ),
                          ),
                          child: Center(child: Text('${index + 1}')),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_box),
                            tooltip: 'Add Blank Frame',
                            onPressed: addFrame,
                          ),
                          IconButton(
                            icon: const Icon(Icons.control_point_duplicate),
                            tooltip: 'Duplicate Frame',
                            onPressed: duplicateFrame,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Frame',
                            onPressed: frames.length > 1 ? deleteFrame : null,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class AnimationPainter extends CustomPainter {
  final AnimationFrame currentFrame;
  final AnimationFrame? previousFrame;

  AnimationPainter({required this.currentFrame, this.previousFrame});

  @override
  void paint(Canvas canvas, Size size) {
    if (previousFrame != null) {
      _paintFrame(canvas, previousFrame!, opacity: 0.3);
    }
    _paintFrame(canvas, currentFrame, opacity: 1.0);
  }

  void _paintFrame(Canvas canvas, AnimationFrame frame, {required double opacity}) {
    for (var stroke in frame.strokes) {
      final paint = Paint()
        ..color = stroke.color.withOpacity(opacity)
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        } else if (stroke.points[i] != null && stroke.points[i + 1] == null) {
          canvas.drawPoints(PointMode.points, [stroke.points[i]!], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // We repaint frequently
  }
}
