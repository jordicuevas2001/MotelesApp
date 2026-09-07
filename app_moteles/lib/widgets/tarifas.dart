import 'package:flutter/material.dart';

class TarifasRow extends StatelessWidget {
  const TarifasRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tarjetaTarifa("1 Hora", "\$60"),
        _tarjetaTarifa("2 Horas", "\$100"),
        _tarjetaTarifa("3 Horas", "\$150"),
        _tarjetaTarifa("4 Horas", "\$200"),
      ],
    );
  }
  
  Widget _tarjetaTarifa(String tiempo, String precio) {
    
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A4A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      
      child: Column(
        children: [
          Text(
            tiempo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            precio,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),   
        ],
      ),
    );
  }
}