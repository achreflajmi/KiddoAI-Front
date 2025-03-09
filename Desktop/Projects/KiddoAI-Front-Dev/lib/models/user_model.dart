class User {
  final String nom;
  final String prenom;
  final String email;
  final String? threadId;
  final String? favoriteCharacter;
  final String? dateOfBirth;

  User({
    required this.nom,
    required this.prenom,
    required this.email,
    this.threadId,
    this.favoriteCharacter,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      threadId: json['threadId'],
      favoriteCharacter: json['favoriteCharacter'],
      dateOfBirth: json['dateNaissance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'threadId': threadId,
      'favoriteCharacter': favoriteCharacter,
      'dateNaissance': dateOfBirth,
    };
  }
}