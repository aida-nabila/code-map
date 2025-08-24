import 'package:flutter/material.dart';
import '../../models/user_profile_match.dart';
import '../../services/api_service.dart';

class JobRecommendationsScreen extends StatefulWidget {
  final int userTestId;

  const JobRecommendationsScreen({super.key, required this.userTestId});

  @override
  State<JobRecommendationsScreen> createState() =>
      _JobRecommendationsScreenState();
}

class _JobRecommendationsScreenState extends State<JobRecommendationsScreen> {
  UserProfileMatchResponse? _profileMatch;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool> _expandedCards = {}; // Track which cards are expanded

  @override
  void initState() {
    super.initState();
    _fetchProfileMatch();
  }

  Future<void> _fetchProfileMatch() async {
    try {
      final result = await ApiService.getUserProfileMatch(
        userTestId: widget.userTestId,
      );

      if (result == null) {
        setState(() {
          _errorMessage = "Failed to fetch profile match.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _profileMatch = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Toggle card expansion state
  void _toggleCardExpansion(int jobIndex) {
    setState(() {
      _expandedCards[jobIndex] = !(_expandedCards[jobIndex] ?? false);
    });
  }

  // Helper function to format the profile text with better structure
  List<Widget> _formatProfileText(String text) {
    final List<Widget> widgets = [];
    final lines = text.split(';');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a heading
      if (line.toLowerCase().contains('user profile:') ||
          line.toLowerCase().contains('top job matches:')) {
        widgets.add(
          Text(
            line,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
      // Check if it's a subheading
      else if (line.contains(':')) {
        final parts = line.split(':');
        widgets.add(
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '${parts[0]}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: parts.length > 1 ? parts[1] : ''),
              ],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }
      // Regular bullet point
      else {
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(
                child: Text(
                  line,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 4));
      }
    }

    return widgets;
  }

  Widget _buildJobCard(JobMatch job) {
    final bool isExpanded = _expandedCards[job.jobIndex] ?? false;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleCardExpansion(job.jobIndex),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.jobTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(
                      "${job.similarityPercentage.toStringAsFixed(2)}% Match",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getMatchColor(job.similarityPercentage),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Short preview of job description
              if (!isExpanded) _buildShortJobPreview(job.jobDescription),

              // Full job description when expanded
              if (isExpanded) ...[
                const SizedBox(height: 12),
                ..._buildFullJobDescription(job.jobDescription),
              ],

              // Expand/collapse indicator
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Job Index: ${job.jobIndex}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build short preview of job description
  Widget _buildShortJobPreview(String description) {
    // Extract first sentence or first 120 characters
    String previewText = description;

    // Try to find the first sentence ending
    final firstPeriod = description.indexOf('.');
    if (firstPeriod != -1 && firstPeriod < 120) {
      previewText = description.substring(0, firstPeriod + 1);
    } else {
      // Fallback: first 120 characters with ellipsis
      previewText = description.length > 120
          ? '${description.substring(0, 120)}...'
          : description;
    }

    return Text(
      previewText,
      style: const TextStyle(fontSize: 14, color: Colors.grey),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Build full job description with formatting
  List<Widget> _buildFullJobDescription(String description) {
    final List<Widget> widgets = [];

    widgets.add(
      const Text(
        "Responsibilities:",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
    widgets.add(const SizedBox(height: 8));

    widgets.addAll(_formatJobDescription(description));

    return widgets;
  }

  // Helper to format job description
  List<Widget> _formatJobDescription(String description) {
    final List<Widget> widgets = [];
    final lines = description.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a bullet point
      if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    line.substring(2).trim(),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Regular paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  // Helper to get color based on match percentage
  Color _getMatchColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Recommendations"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Your Profile Summary",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _formatProfileText(_profileMatch!.profileText),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Job Recommendations Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Recommended Career",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._profileMatch!.topMatches
                          .map((job) => _buildJobCard(job))
                          .toList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
