// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({GitHub? client}) : github = client ?? MockGitHub();
  late List<RepositoryCommit> Function(String, int) listCommitsBranch;
  late List<PullRequest> Function(String?) listPullRequestsBranch;

  @override
  final GitHub github;

  @override
  Future<List<RepositoryCommit>> listBranchedCommits(
    RepositorySlug slug,
    String branch,
    int? lastCommitTimestampMills,
  ) async {
    return listCommitsBranch(branch, lastCommitTimestampMills ?? 0);
  }

  final List<(RepositorySlug, String)> deletedBranches = [];

  @override
  Future<bool> deleteBranch(RepositorySlug slug, String branchName) async {
    deletedBranches.add((slug, branchName));
    return true;
  }

  @override
  Future<List<PullRequest>> listPullRequests(
    RepositorySlug slug,
    String? branch,
  ) async {
    return listPullRequestsBranch(branch);
  }

  @override
  Future<List<IssueLabel>> addIssueLabels(
    RepositorySlug slug,
    int issueNumber,
    List<String> labels,
  ) async {
    return <IssueLabel>[];
  }

  final List<(RepositorySlug slug, int issueNumber, String label)>
  removedLabels = [];

  @override
  Future<bool> removeLabel(
    RepositorySlug slug,
    int issueNumber,
    String label,
  ) async {
    removedLabels.add((slug, issueNumber, label));
    return true;
  }

  @override
  Future<void> assignReviewer(
    RepositorySlug slug, {
    int? pullRequestNumber,
    String? reviewer,
  }) async {}

  @override
  Future<Issue> createIssue(
    RepositorySlug slug, {
    String? title,
    String? body,
    List<String?>? labels,
    String? assignee,
  }) async {
    return Issue();
  }

  @override
  Future<void> assignIssue(
    RepositorySlug slug, {
    int? issueNumber,
    String? assignee,
  }) async {
    return;
  }

  @override
  Future<PullRequest> createPullRequest(
    RepositorySlug slug, {
    String? title,
    String? body,
    String? commitMessage,
    GitReference? baseRef,
    List<CreateGitTreeEntry>? entries,
  }) async {
    return PullRequest();
  }

  @override
  Future<String> getFileContent(
    RepositorySlug slug,
    String path, {
    String? ref,
  }) async {
    return GithubService(github).getFileContent(slug, path, ref: ref);
  }

  @override
  Future<List<String>> listFiles(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    return <String>['abc/def'];
  }

  GitReference Function() getReferenceValue = GitReference.new;
  @override
  Future<GitReference> getReference(RepositorySlug slug, String ref) async {
    return getReferenceValue();
  }

  @override
  Future<List<IssueLabel>> getIssueLabels(
    RepositorySlug slug,
    int issueNumber,
  ) {
    return Future.value(<IssueLabel>[IssueLabel(name: 'override: test')]);
  }

  @override
  Future<List<Issue>> listIssues(
    RepositorySlug slug, {
    List<String>? labels,
    String state = 'open',
  }) async {
    return <Issue>[];
  }

  @override
  Future<Issue>? getIssue(RepositorySlug slug, {int? issueNumber}) {
    return null;
  }

  final List<(RepositorySlug slug, {int? issueNumber, String? body})>
  createdComments = [];

  @override
  Future<IssueComment?> createComment(
    RepositorySlug slug, {
    int? issueNumber,
    String? body,
  }) async {
    createdComments.add((slug, issueNumber: issueNumber, body: body));
    return null;
  }

  @override
  Future<List<IssueLabel>> replaceLabelsForIssue(
    RepositorySlug slug, {
    int? issueNumber,
    List<String>? labels,
  }) async {
    return <IssueLabel>[];
  }

  @override
  Future<RateLimit> getRateLimit() {
    throw UnimplementedError();
  }

  @override
  Future<PullRequest> getPullRequest(RepositorySlug slug, int number) async {
    return PullRequest();
  }

  @override
  Future<List<Issue>> searchIssuesAndPRs(
    RepositorySlug slug,
    String query, {
    String? sort,
    int pages = 2,
  }) async {
    return <Issue>[];
  }

  Map<int, List<PullRequestReview>> mockPullRequestReviews = {};

  String? checkRunsMock;

  @override
  Future<List<CheckRun>> getCheckRuns(RepositorySlug slug, String ref) async {
    final rawBody = json.decode(checkRunsMock!) as Map<String, dynamic>;
    final checkRunsBody = rawBody['check_runs']! as List<dynamic>;
    final checkRuns = <CheckRun>[];
    if ((checkRunsBody[0] as Map<String, dynamic>).isNotEmpty) {
      checkRuns.addAll(
        checkRunsBody
            .map(
              (dynamic checkRun) =>
                  CheckRun.fromJson(checkRun as Map<String, dynamic>),
            )
            .toList(),
      );
    }
    return checkRuns;
  }

  @override
  Future<List<CheckRun>> getCheckRunsFiltered({
    required RepositorySlug slug,
    required String ref,
    String? checkName,
    CheckRunStatus? status,
    CheckRunFilter? filter,
  }) async {
    final checkRuns = await getCheckRuns(slug, ref);
    if (checkName != null) {
      final checkRunsFilteredByName = <CheckRun>[];
      for (var checkRun in checkRuns) {
        if (checkRun.name == checkName && checkRun.headSha == ref) {
          checkRunsFilteredByName.add(checkRun);
        }
      }
      return checkRunsFilteredByName;
    }
    return checkRuns;
  }

  final List<
    ({
      RepositorySlug slug,
      CheckRun checkRun,
      String? name,
      String? detailsUrl,
      String? externalId,
      DateTime? startedAt,
      CheckRunStatus status,
      CheckRunConclusion? conclusion,
      DateTime? completedAt,
      CheckRunOutput? output,
      List<CheckRunAction>? actions,
    })
  >
  checkRunUpdates = [];

  @override
  Future<CheckRun> updateCheckRun({
    required RepositorySlug slug,
    required CheckRun checkRun,
    String? name,
    String? detailsUrl,
    String? externalId,
    DateTime? startedAt,
    CheckRunStatus status = CheckRunStatus.queued,
    CheckRunConclusion? conclusion,
    DateTime? completedAt,
    CheckRunOutput? output,
    List<CheckRunAction>? actions,
  }) async {
    final Map<String, Object?> json = checkRun.toJson();

    checkRunUpdates.add((
      slug: slug,
      checkRun: checkRun,
      name: name,
      detailsUrl: detailsUrl,
      externalId: externalId,
      startedAt: startedAt,
      status: status,
      conclusion: conclusion,
      completedAt: completedAt,
      output: output,
      actions: actions,
    ));

    if (conclusion != null) {
      json['conclusion'] = conclusion.value;
    }

    if (status != checkRun.status) {
      json['status'] = status.value;
    }

    return CheckRun.fromJson(json);
  }

  final commentExistsCalls =
      <({RepositorySlug slug, int issue, String body})>[];
  bool commentExistsMock = false;

  @override
  Future<bool> commentExists(
    RepositorySlug slug,
    int issue,
    String body,
  ) async {
    commentExistsCalls.add((slug: slug, issue: issue, body: body));
    return commentExistsMock;
  }
}
