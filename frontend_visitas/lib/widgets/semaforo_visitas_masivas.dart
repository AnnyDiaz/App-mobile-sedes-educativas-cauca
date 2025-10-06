import 'package:flutter/material.dart';

enum EstadoCampo {
  completo,    // 🟢 Verde
  incompleto,  // 🟡 Amarillo  
  faltante     // 🔴 Rojo
}

class SemaforoVisitasMasivas extends StatelessWidget {
  final List<int> sedesSeleccionadas;
  final List<int> visitadoresSeleccionados;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String tipoVisita;
  final String distribucion;

  const SemaforoVisitasMasivas({
    Key? key,
    required this.sedesSeleccionadas,
    required this.visitadoresSeleccionados,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipoVisita,
    required this.distribucion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final campos = _evaluarCampos();
    final estadoGeneral = _calcularEstadoGeneral(campos);
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.traffic,
                  color: _getColorEstado(estadoGeneral),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Estado de Configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getColorEstado(estadoGeneral),
                  ),
                ),
                Spacer(),
                _buildIndicadorEstado(estadoGeneral),
              ],
            ),
            SizedBox(height: 16),
            ...campos.entries.map((campo) => _buildCampoItem(campo)),
            SizedBox(height: 12),
            _buildResumenGeneral(campos, estadoGeneral),
          ],
        ),
      ),
    );
  }

  Map<String, EstadoCampo> _evaluarCampos() {
    return {
      'sedes': sedesSeleccionadas.isNotEmpty ? EstadoCampo.completo : EstadoCampo.faltante,
      'visitadores': visitadoresSeleccionados.isNotEmpty ? EstadoCampo.completo : EstadoCampo.faltante,
      'fechaInicio': fechaInicio != null ? EstadoCampo.completo : EstadoCampo.faltante,
      'fechaFin': fechaFin != null ? EstadoCampo.completo : EstadoCampo.faltante,
      'tipoVisita': tipoVisita.isNotEmpty ? EstadoCampo.completo : EstadoCampo.faltante,
      'distribucion': distribucion.isNotEmpty ? EstadoCampo.completo : EstadoCampo.faltante,
    };
  }

  EstadoCampo _calcularEstadoGeneral(Map<String, EstadoCampo> campos) {
    final valores = campos.values.toList();
    
    if (valores.every((estado) => estado == EstadoCampo.completo)) {
      return EstadoCampo.completo;
    } else if (valores.any((estado) => estado == EstadoCampo.faltante)) {
      return EstadoCampo.faltante;
    } else {
      return EstadoCampo.incompleto;
    }
  }

  Widget _buildIndicadorEstado(EstadoCampo estado) {
    String texto;
    Color color;
    
    switch (estado) {
      case EstadoCampo.completo:
        texto = 'Completo';
        color = Colors.green;
        break;
      case EstadoCampo.incompleto:
        texto = 'Incompleto';
        color = Colors.orange;
        break;
      case EstadoCampo.faltante:
        texto = 'Faltante';
        color = Colors.red;
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCampoItem(MapEntry<String, EstadoCampo> campo) {
    final nombre = _getNombreCampo(campo.key);
    final estado = campo.value;
    final valor = _getValorCampo(campo.key);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildIconoEstado(estado),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (valor.isNotEmpty)
                  Text(
                    valor,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconoEstado(EstadoCampo estado) {
    IconData icono;
    Color color;
    
    switch (estado) {
      case EstadoCampo.completo:
        icono = Icons.check_circle;
        color = Colors.green;
        break;
      case EstadoCampo.incompleto:
        icono = Icons.warning;
        color = Colors.orange;
        break;
      case EstadoCampo.faltante:
        icono = Icons.error;
        color = Colors.red;
        break;
    }
    
    return Icon(icono, color: color, size: 20);
  }

  Widget _buildResumenGeneral(Map<String, EstadoCampo> campos, EstadoCampo estadoGeneral) {
    final completos = campos.values.where((e) => e == EstadoCampo.completo).length;
    final total = campos.length;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getColorEstado(estadoGeneral).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColorEstado(estadoGeneral).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _getColorEstado(estadoGeneral),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getMensajeResumen(estadoGeneral, completos, total),
              style: TextStyle(
                color: _getColorEstado(estadoGeneral),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNombreCampo(String key) {
    switch (key) {
      case 'sedes': return 'Sedes Educativas';
      case 'visitadores': return 'Visitadores';
      case 'fechaInicio': return 'Fecha de Inicio';
      case 'fechaFin': return 'Fecha de Fin';
      case 'tipoVisita': return 'Tipo de Visita';
      case 'distribucion': return 'Distribución';
      default: return key;
    }
  }

  String _getValorCampo(String key) {
    switch (key) {
      case 'sedes': return '${sedesSeleccionadas.length} sede(s) seleccionada(s)';
      case 'visitadores': return '${visitadoresSeleccionados.length} visitador(es) seleccionado(s)';
      case 'fechaInicio': return fechaInicio?.toString().split(' ')[0] ?? 'No seleccionada';
      case 'fechaFin': return fechaFin?.toString().split(' ')[0] ?? 'No seleccionada';
      case 'tipoVisita': return tipoVisita;
      case 'distribucion': return distribucion == 'automatica' ? 'Automática' : 'Manual';
      default: return '';
    }
  }

  Color _getColorEstado(EstadoCampo estado) {
    switch (estado) {
      case EstadoCampo.completo: return Colors.green;
      case EstadoCampo.incompleto: return Colors.orange;
      case EstadoCampo.faltante: return Colors.red;
    }
  }

  String _getMensajeResumen(EstadoCampo estado, int completos, int total) {
    switch (estado) {
      case EstadoCampo.completo:
        return '✅ Todos los campos están completos. Listo para programar visitas masivas.';
      case EstadoCampo.incompleto:
        return '⚠️ $completos de $total campos completos. Revisa los campos faltantes.';
      case EstadoCampo.faltante:
        return '❌ Faltan campos obligatorios. Completa la información para continuar.';
    }
  }
}
