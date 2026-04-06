import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../../data/models/message_model.dart';
import 'package:uuid/uuid.dart';

class MessageInput extends StatefulWidget {
  final String trackingId;
  final String currentUserId;
  final String currentUserName;

  const MessageInput({
    super.key,
    required this.trackingId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendMessage(
        mediaFile: File(image.path),
        messageType: MessageType.image,
        fileExtension: image.path.split('.').last,
      );
    }
  }

  Future<void> _pickDocument() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _sendMessage(
        mediaFile: file,
        messageType: MessageType.document,
        fileExtension: result.files.single.extension,
        text: result.files.single.name,
      );
    }
  }

  Future<void> _shareLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _sendMessage(
      text: '${position.latitude},${position.longitude}',
      messageType: MessageType.location,
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMessage(
          mediaFile: File(path),
          messageType: MessageType.voice,
          fileExtension: 'm4a',
        );
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/${const Uuid().v4()}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  void _sendMessage({
    String? text,
    File? mediaFile,
    required MessageType messageType,
    String? fileExtension,
  }) {
    if (text == null && mediaFile == null) return;

    context.read<ChatBloc>().add(
      SendMessage(
        trackingId: widget.trackingId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: text,
        mediaFile: mediaFile,
        messageType: messageType,
        fileExtension: fileExtension,
      ),
    );
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.attach_file, color: Colors.blue),
              onSelected: (item) {
                if (item == 0) _pickImage();
                if (item == 1) _pickDocument();
                if (item == 2) _shareLocation();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 8),
                      Text('Image'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file),
                      SizedBox(width: 8),
                      Text('Document'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8),
                      Text('Location'),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
              onPressed: _toggleRecording,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                final txt = _controller.text.trim();
                if (txt.isNotEmpty) {
                  _sendMessage(text: txt, messageType: MessageType.text);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
