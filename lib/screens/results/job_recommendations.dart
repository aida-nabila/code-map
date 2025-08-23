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

  Widget _buildJobCard(JobMatch job) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.jobTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              job.jobDescription,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Similarity: ${job.similarityPercentage.toStringAsFixed(2)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Job Index: ${job.jobIndex}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile & Job Recommendations"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Text Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "User Profile:",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(_profileMatch!.profileText),
                      ),
                      const SizedBox(height: 24),

                      // Job Recommendations Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Top Job Matches:",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
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
