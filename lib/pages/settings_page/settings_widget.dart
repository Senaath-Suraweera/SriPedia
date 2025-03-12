import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'settingspage_model.dart';
export 'settingspage_model.dart';

class SettingspageWidget extends StatefulWidget {
  const SettingspageWidget({super.key});

  static String routeName = 'settingspage';
  static String routePath = '/settingspage';

  @override
  State<SettingspageWidget> createState() => _SettingspageWidgetState();
}

class _SettingspageWidgetState extends State<SettingspageWidget> {
  late SettingspageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingspageModel());

    _model.switchValue1 = true;
    _model.switchValue2 = true;
    _model.switchValue3 = true;
    _model.switchValue4 = true;
    _model.switchValue5 = true;
    _model.switchValue6 = true;
    _model.switchValue7 = true;
    _model.switchValue8 = true;
    _model.switchValue9 = true;
    _model.switchValue10 = true;
    _model.switchValue11 = true;
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Color(0xFF6F61EF),
          automaticallyImplyLeading: false,
          title: Text(
            'Settings',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 18, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'PROFILE SETTINGS',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: Image.network(
                                      '500x500?person',
                                    ).image,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'John Smith',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            fontFamily: 'Inter',
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '@johnsmith',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0, 8, 0, 0),
                                      child: FFButtonWidget(
                                        onPressed: () {
                                          print('Button pressed ...');
                                        },
                                        text: 'Change Avatar',
                                        options: FFButtonOptions(
                                          height: 36,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12, 8, 12, 8),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0, 0, 0, 0),
                                          color: FlutterFlowTheme.of(context)
                                              .accent1,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .labelMedium
                                              .override(
                                                fontFamily: 'Inter',
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          elevation: 0,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(width: 16)),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Update Profile',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Change username and display name',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Change Password',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Update your account password',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Linked Accounts',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Manage connected social accounts',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Language',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'English',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'PRIVACY & SECURITY',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Two-Factor Authentication',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue1!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue1 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Privacy Controls',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Manage who can view your progress',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Data Usage & Permissions',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Control how your data is used',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Analytics Collection',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue2!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue2 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'NOTIFICATION PREFERENCES',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.quiz,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Quiz Reminders',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue3!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue3 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'New Classroom Assignments',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue4!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue4 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.leaderboard,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Leaderboard Updates',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue5!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue5 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Chatbot Alerts',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue6!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue6 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'AUDIO & VISUAL SETTINGS',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Background Music',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue7!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue7 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.volume_up,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Sound Effects',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue8!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue8 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Text Size & Contrast',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Adjust for better readability',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dark_mode,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Dark Mode',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue9!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue9 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'GAMIFICATION CONTROLS',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.animation,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Avatar Animations',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue10!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue10 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.leaderboard,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  Text(
                                    'Show Leaderboard Position',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .override(
                                          fontFamily: 'Inter',
                                          letterSpacing: 0.0,
                                        ),
                                  ),
                                ].divide(SizedBox(width: 12)),
                              ),
                              Switch(
                                value: _model.switchValue11!,
                                onChanged: (newValue) async {
                                  safeSetState(
                                      () => _model.switchValue11 = newValue!);
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor:
                                    FlutterFlowTheme.of(context).accent1,
                                inactiveTrackColor:
                                    FlutterFlowTheme.of(context).alternate,
                                inactiveThumbColor:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                            ],
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: FlutterFlowTheme.of(context).alternate,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Earned Cosmetics',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'View and manage your collection',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Point History',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Track your progress over time',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'HELP & SUPPORT',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Contact Support',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Get help with any issues',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'FAQs',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Frequently asked questions',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Report a Bug',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              subtitle: Text(
                                'Help us improve the app',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'LEGAL',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Terms of Service',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Privacy Policy',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              dense: false,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              title: Text(
                                'Delete Account',
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Inter',
                                      color: Color(0xFFFF0000),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              tileColor: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              dense: false,
                            ),
                          ),
                        ].divide(SizedBox(height: 16)),
                      ),
                    ),
                  ),
                ),
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      'Version 1.0.5',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            color: FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
