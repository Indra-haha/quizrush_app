import '../helpers/json.dart';

class Quizes {
  final String id;
  final String userId;
  final String host;
  final String title;
  final String description;
  final String path;
  final List<QuizQuestion> questions;
  final int totalQuestions;
  final double totalDuration;
  final int totalSkor;
  final String createdAt;
  final String status;
  final List<RoomSummary> rooms;

  const Quizes({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdAt,
    this.host = '',
    this.totalQuestions = 0,
    this.totalDuration = 0,
    this.totalSkor = 0,
    this.path = '',
    this.status = '',
    this.rooms = const [],
  });

  /// Jumlah soal: pakai ringkasan `total_questions` kalau ada, kalau tidak
  /// dihitung dari daftar soal mentah (`/api/my-quizzes`).
  int get questionCount =>
      totalQuestions > 0 ? totalQuestions : questions.length;

  /// Total durasi (detik): pakai ringkasan `total_duration` kalau ada, kalau
  /// tidak dijumlahkan dari durasi tiap soal.
  double get durationSeconds => totalDuration > 0
      ? totalDuration
      : questions.fold<double>(0, (sum, q) => sum + q.duration);

  /// Total skor: pakai ringkasan `total_skor` kalau ada, kalau tidak
  /// dijumlahkan dari skor tiap soal.
  int get score =>
      totalSkor > 0 ? totalSkor : questions.fold<int>(0, (sum, q) => sum + q.skor);

  factory Quizes.fromJson(Map<String, dynamic> json) {
    return Quizes(
      id: jsonString(json['id']),
      userId: jsonString(json['user_id']),
      host: jsonString(json['host']),
      title: jsonString(json['title']),
      description: jsonString(json['description']),
      path: jsonString(json['path']),
      questions: jsonMapList(
        json['questions'],
      ).map(QuizQuestion.fromJson).toList(),
      totalQuestions: jsonInt(json['total_questions']),
      totalDuration: jsonDouble(json['total_duration']),
      totalSkor: jsonInt(json['total_skor']),
      createdAt: jsonString(json['created_at']),
      status: jsonString(json['status']),
      rooms: jsonMapList(
        json['rooms'],
      ).map(RoomSummary.fromJson).toList(),
    );
  }

  /// Bentuk yang disimpan ke cache mengikuti payload feed publik: ringkasan
  /// `host`/`total_*` selalu ditulis, sedangkan field mentah (`user_id`,
  /// `questions`, `status`) hanya disertakan kalau tidak kosong.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'host': host,
      'title': title,
      'description': description,
      'path': path,
      'total_questions': questionCount,
      'total_duration': durationSeconds,
      'total_skor': score,
      'created_at': createdAt,
      'rooms': rooms.map((r) => r.toJson()).toList(),
    };
    if (userId.isNotEmpty) map['user_id'] = userId;
    if (status.isNotEmpty) map['status'] = status;
    if (questions.isNotEmpty) {
      map['questions'] = questions.map((q) => q.toJson()).toList();
    }
    return map;
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final double duration;
  final int skor;

  const QuizQuestion({
    required this.question,
    required this.options,
    this.duration = 0,
    this.skor = 0,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: jsonString(json['question']),
      options: jsonStringList(json['options']),
      duration: jsonDouble(json['duration']),
      skor: jsonInt(json['skor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'duration': duration,
      'skor': skor,
    };
  }
}

class QuizQuestionInput {
  final String question;
  final List<String> options;
  final int correctIdx;
  final double duration;
  final int skor;

  const QuizQuestionInput({
    required this.question,
    required this.options,
    required this.correctIdx,
    required this.duration,
    required this.skor,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correct_idx': correctIdx,
      'duration': duration,
      'skor': skor,
    };
  }
}

class RoomSummary {
  final String id;
  final String kode;
  final String status;
  final String createdAt;
  final String judul;
  final String isi;

  const RoomSummary({
    required this.id,
    required this.kode,
    required this.status,
    required this.createdAt,
    this.judul = '',
    this.isi = '',
  });

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(
      id: jsonString(json['id']),
      kode: jsonString(json['kode']),
      status: jsonString(json['status']),
      createdAt: jsonString(json['created_at']),
      judul: jsonString(json['judul']),
      isi: jsonString(json['isi']),
    );
  }

  /// `kode` hanya ditulis kalau ada (feed publik tidak mengembalikan PIN).
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'status': status,
      'created_at': createdAt,
      'judul': judul,
      'isi': isi,
    };
    if (kode.isNotEmpty) map['kode'] = kode;
    return map;
  }
}

class QuizSummary {
  final String id;
  final String title;
  final String description;
  final int totalQuestions;

  const QuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: jsonString(json['id']),
      title: jsonString(json['title']),
      description: jsonString(json['description']),
      totalQuestions: jsonInt(json['total_questions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'total_questions': totalQuestions,
    };
  }
}

class MyQuizzes {
  final List<Quizes> waiting;
  final List<Quizes> open;
  final List<Quizes> inGame;
  final List<Quizes> ended;
  final List<Quizes> quarantine;

  const MyQuizzes({
    this.waiting = const [],
    this.open = const [],
    this.inGame = const [],
    this.ended = const [],
    this.quarantine = const [],
  });

  factory MyQuizzes.fromJson(Map<String, dynamic> json) {
    List<Quizes> parse(String key) {
      return jsonMapList(json[key]).map(Quizes.fromJson).toList();
    }

    return MyQuizzes(
      waiting: parse('waiting'),
      open: parse('open'),
      inGame: parse('in-Game'),
      ended: parse('ended'),
      quarantine: parse('quarantine'),
    );
  }

  List<Quizes> get all => [
    ...waiting,
    ...open,
    ...inGame,
    ...ended,
    ...quarantine,
  ];

  bool get isEmpty => all.isEmpty;

  List<({String status, List<Quizes> quizzes})> get groups => [
    (status: 'waiting', quizzes: waiting),
    (status: 'open', quizzes: open),
    (status: 'in-Game', quizzes: inGame),
    (status: 'ended', quizzes: ended),
    (status: 'quarantine', quizzes: quarantine),
  ];
}

class AllQuizzes {
  final List<Quizes> open;
  final List<Quizes> inGame;
  final List<Quizes> ended;

  const AllQuizzes({
    this.open = const [],
    this.inGame = const [],
    this.ended = const [],
  });

  factory AllQuizzes.fromJson(Map<String, dynamic> json) {
    List<Quizes> parse(String key) {
      return jsonMapList(json[key]).map(Quizes.fromJson).toList();
    }

    return AllQuizzes(
      open: parse('open'),
      inGame: parse('in-Game'),
      ended: parse('ended'),
    );
  }

  List<Quizes> get all => [...open, ...inGame, ...ended];

  List<({String status, List<Quizes> quizzes})> get groups => [
    (status: 'open', quizzes: open),
    (status: 'in-Game', quizzes: inGame),
    (status: 'ended', quizzes: ended),
  ];
}
