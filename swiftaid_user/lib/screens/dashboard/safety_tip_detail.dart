import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SafetyTipDetail extends StatelessWidget {
  final Map<String, dynamic> tip;
  const SafetyTipDetail({Key? key, required this.tip}) : super(key: key);

  /// Convert the multiline string in `details` to a list of steps
  List<String> _parseSteps(String raw) {
    // Split on newlines and remove empties/emoji numbers
    return raw
        .split('\n')
        .map((line) => line
            .replaceAll(RegExp(r'^\s*[\d️⃣\.•]+'), '')
            .trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final red = const Color(0xFFB71C1C);
    final steps = _parseSteps(tip['details'] ?? tip['desc'] ?? '');
    final String? videoUrl = tip['videoUrl'];
    final String? videoId =
        (videoUrl != null && videoUrl.isNotEmpty) ? YoutubePlayer.convertUrlToId(videoUrl) : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: red,
        title: Text(tip['title'] ?? 'Safety Tip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decorative header
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb, color: red, size: 56),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                tip['title'] ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Step-by-Step Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final stepNum = i + 1;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circle with number
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$stepNum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Step text
                      Expanded(
                        child: Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: isDark ? Colors.grey[200] : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            if (videoId != null) ...[
              Text(
                'Watch Video Guide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YoutubePlayer(
                    controller: YoutubePlayerController(
                      initialVideoId: videoId,
                      flags: const YoutubePlayerFlags(
                        autoPlay: false,
                        controlsVisibleAtStart: true,
                      ),
                    ),
                    showVideoProgressIndicator: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
