// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/feed_icons.dart' show ApawFrontDoor, ApawFeature;

/// Feed-a-Paw's front door: the shared a-Paw welcome and sign-in (ApawFrontDoor,
/// laid out like Spot a Paw's), with Feed-a-Paw's own logo, promise and features.
class FeedAuthPanel extends StatefulWidget {
  const FeedAuthPanel({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<FeedAuthPanel> createState() => _FeedAuthPanelState();
}

class _FeedAuthPanelState extends State<FeedAuthPanel> {
  @override
  Widget build(BuildContext context) => ApawFrontDoor(
        app: 'feed',
        name: 'Feed-a-Paw',
        promise: 'Street animals, fed every day.',
        blurb: 'Follow the food truck, the feeding rounds and their stories.',
        features: const [
          ApawFeature('feed-nav-map', 'Feeding spots', 'Where the truck and feeders stop today.'),
          ApawFeature('feed-nav-stories', 'Stories', 'The animals we meet on every round.'),
          ApawFeature('feed-about-edible-plate', 'Edible plates', 'Every meal is served on a plate they can eat.'),
          ApawFeature('feed-today-truck-fund', 'The food truck', 'Follow the first truck on its way to Cairo.'),
        ],
        meals: 'Feed-a-Paw is One Tail One Meal’s own app, feeding street animals every day.',
        homeRoute: 'DriverPage',
        guestLabel: 'Look around first',
        guestRoute: 'TodayPage',
        width: widget.width,
        height: widget.height,
      );
}
