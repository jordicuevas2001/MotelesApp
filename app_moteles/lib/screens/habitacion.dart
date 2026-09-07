class Habitacion {
  final int id; 
  final int numero;
  bool ocupada;
  DateTime? horaEntrada; 

  Habitacion({
    required this.id,
    required this.numero,
    this.ocupada = false,
    this.horaEntrada,
  });

  factory Habitacion.fromJson(Map<String, dynamic> json) {
    final registroActivo = json['registro_activo'];

    return Habitacion(
      id: json['id'],
      numero: json['numero'],
      ocupada: json['ocupado'] == true || json['ocupado'] == 1,
      horaEntrada: registroActivo != null
          ? DateTime.parse(registroActivo['hora_entrada'])
          : null,
    );
  }
}