// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../common/json_converters.dart';

part 'pubsub_message.g.dart';

// TODO (ricardoamador) look to see how this can be removed in favor of the gcloud lib pub/sub.
// the initial finding is that it may be an issue with how gcloud packages the
// message.
@JsonSerializable(includeIfNull: false)
@immutable
final class PubSubPushMessage {
  const PubSubPushMessage({this.message, this.subscription});

  factory PubSubPushMessage.fromJson(Map<String, Object?> json) =>
      _$PubSubPushMessageFromJson(json);

  /// The message contents.
  final PushMessage? message;

  /// The name of the subscription associated with the delivery.
  final String? subscription;

  Map<String, Object?> toJson() => _$PubSubPushMessageToJson(this);
}

// Rename this to PushMessage as it is basically that class.
@JsonSerializable(includeIfNull: false)
@immutable
final class PushMessage {
  const PushMessage({
    this.attributes,
    this.data,
    this.messageId,
    this.publishTime,
  });

  /// PubSub attributes on the message.
  final Map<String, String>? attributes;

  /// The raw string data of the message.
  @Base64Converter()
  final String? data;

  /// A identifier for the message from PubSub.
  final String? messageId;

  /// The time at which the message was published, populated by the server when
  /// it receives the topics.publish call.
  ///
  /// A timestamp in RFC3339 UTC "Zulu" format, with nanosecond resolution and
  /// up to nine fractional digits. Examples: "2014-10-02T15:01:23Z" and
  /// "2014-10-02T15:01:23.045123456Z".
  final String? publishTime;

  factory PushMessage.fromJson(Map<String, Object?> json) =>
      _$PushMessageFromJson(json);

  Map<String, Object?> toJson() => _$PushMessageToJson(this);
}
