import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:firebase_model_generator/firebase_model_generator.dart';
import 'package:source_gen/source_gen.dart';

class ModelVisitor extends SimpleElementVisitor {
  DartType className;
  Map<String, DartType> fields = {};

  @override
  visitConstructorElement(ConstructorElement element) {
    assert(className != null);
    className = element.type.returnType;
  }

  @override
  visitFieldElement(FieldElement element) {
    fields[element.name] = element.type;
  }
}

class FirebaseModelGenerator extends GeneratorForAnnotation<FirebaseModel> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var visitor = ModelVisitor();
    element.visitChildren(visitor);

    return " ${_buildModel(visitor)} \n ${_buildEntity(visitor)}";
  }

  String _buildModel(ModelVisitor visitor) {
    String className = visitor.className.getDisplayString();
    if (className.startsWith('\$')) {
      className = className.substring(1);
    } else {
      className = "_${visitor.className}";
    }
    Map<String, DartType> fields = visitor.fields;

    final classBuffer = StringBuffer();

    // Add class declaration
    classBuffer.writeln("@immutable");
    classBuffer.writeln("class $className {");

    // Add constructor
    classBuffer.writeln("$className(");
    for (var parameterName in fields.keys.where((value) => value != 'id')) {
      classBuffer.writeln("this.$parameterName,");
    }
    if (fields.keys.contains('id')) {
      classBuffer.writeln("{this.id,}");
    }

    classBuffer.writeln("");
    classBuffer.writeln(");");

    // Add variables declarations
    for (var parameterName in fields.keys) {
      classBuffer.writeln("final ${fields[parameterName]} $parameterName;");
    }
    classBuffer.writeln("");

    // Add copyWith method
    classBuffer.writeln(_buildCopyWith(className, fields));

    // Add toString method
    classBuffer.writeln(_buildToString(className, fields));

    // Add operator== method
    classBuffer.writeln(_buildOperator(className, fields));

    // Add hashCode method
    classBuffer.writeln(_buildHashCode(className, fields));

    // Add toEntity method
    classBuffer.writeln(_buildToEntity(className, fields));

    // Add fromEntity method
    classBuffer.writeln(_buildFromEntity(className, fields));

    // Close class definition
    classBuffer.writeln("}");
    return classBuffer.toString();
  }

  String _buildCopyWith(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    // Method declaration with arguments
    buffer.writeln("$className copyWith({");
    for (var parameterName in fields.keys) {
      buffer.writeln("${fields[parameterName]} $parameterName,");
    }
    buffer.writeln("}){");

    // Add constructor call
    buffer.writeln("return $className(");
    for (var parameterName in fields.keys.where((element) => element != 'id')) {
      buffer.writeln("$parameterName ?? this.$parameterName,");
    }
    if (fields.keys.contains('id')) {
      buffer.writeln("id: id ?? this.id,");
    }
    buffer.writeln(");}");

    return buffer.toString();
  }

  String _buildToString(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    buffer.writeln("@override");
    buffer.writeln("String toString() {");
    buffer.write("return '$className{");
    for (var parameterName in fields.keys) {
      if (parameterName == fields.keys.last) {
        buffer.write(" $parameterName: \$$parameterName");
      } else {
        buffer.write(" $parameterName: \$$parameterName,");
      }
    }
    buffer.write("}';");
    buffer.writeln("}");
    return buffer.toString();
  }

  String _buildOperator(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    buffer.writeln("@override");
    buffer.writeln("bool operator==(Object other) => ");
    buffer.writeln("identical(this, other) ||");
    buffer.writeln("other is $className &&");
    buffer.writeln("runtimeType == other.runtimeType &&");

    for (var parameterName in fields.keys) {
      if (parameterName == fields.keys.last) {
        buffer.writeln("$parameterName == other.$parameterName;");
      } else {
        buffer.writeln("$parameterName == other.$parameterName &&");
      }
    }
    return buffer.toString();
  }

  String _buildHashCode(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    buffer.writeln("@override");
    buffer.writeln("int get hashCode => ");
    for (var parameterName in fields.keys) {
      if (parameterName == fields.keys.last) {
        buffer.writeln("$parameterName.hashCode;");
      } else {
        buffer.writeln("$parameterName.hashCode ^");
      }
    }
    return buffer.toString();
  }

  String _buildToEntity(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    buffer.writeln("${className}Entity toEntity() {");
    buffer.writeln("return ${className}Entity(");
    for (var parameterName in fields.keys) {
      buffer.writeln("$parameterName, ");
    }

    buffer.writeln(");}");
    return buffer.toString();
  }

  String _buildFromEntity(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();

    buffer
        .writeln("static ${className} fromEntity(${className}Entity entity) {");
    buffer.writeln("return ${className}(");
    for (var parameterName in fields.keys.where((element) => element != 'id')) {
      buffer.writeln("entity.$parameterName,");
    }
    if (fields.keys.contains('id')) {
      buffer.writeln("id: entity.id,");
    }

    buffer.writeln(");}");
    return buffer.toString();
  }

  /// Create Firebase entity class
  String _buildEntity(ModelVisitor visitor) {
    String className = visitor.className.getDisplayString() + "Entity";
    if (className.startsWith('_')) {
      className = className.substring(1);
    } else {
      className = "_${visitor.className}";
    }
    Map<String, DartType> fields = visitor.fields;

    final classBuffer = StringBuffer();

    // Add class declaration
    classBuffer.writeln("class $className extends Equatable {");

    // Add variables declarations
    for (var parameterName in fields.keys) {
      classBuffer.writeln("final ${fields[parameterName]} $parameterName;");
    }
    classBuffer.writeln("");

    // Add constructor
    classBuffer.writeln("$className(");
    for (var parameterName in fields.keys) {
      classBuffer.writeln("this.$parameterName,");
    }

    classBuffer.writeln("");
    classBuffer.writeln(");");

    // Add toJson method
    classBuffer.writeln(_buildToJson(className, fields));

    // Add props method
    classBuffer.writeln(_buildProps(className, fields));

    // Add toString method
    classBuffer.writeln(_buildToString(className, fields));

    // Add fromJson method
    classBuffer.writeln(_buildFromJson(className, fields));

    // Add fromSnapshot method
    classBuffer.writeln(_buildFromSnapshot(className, fields));

    // Add toDocument method
    classBuffer.writeln(_buildToDocument(className, fields));

    // Close class definition
    classBuffer.writeln("}");
    return classBuffer.toString();
  }

  String _buildToJson(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    buffer.writeln("Map<String, Object> toJson(){ return {");

    for (var parameterName in fields.keys) {
      buffer.writeln("\"$parameterName\" : $parameterName,");
    }

    buffer.writeln("};}");
    return buffer.toString();
  }

  String _buildProps(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    buffer.writeln("@override");
    buffer.writeln("List<Object> get props => [");

    for (var parameterName in fields.keys) {
      buffer.writeln("$parameterName,");
    }

    buffer.writeln("];");
    return buffer.toString();
  }

  String _buildFromJson(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    buffer.writeln(
        "static $className fromJson(Map<String,Object> json) { return $className(");

    for (var parameterName in fields.keys) {
      buffer.writeln("json[\"$parameterName\"] as ${fields[parameterName]},");
    }

    buffer.writeln(");}");
    return buffer.toString();
  }

  String _buildFromSnapshot(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    buffer.writeln(
        "static $className fromSnapshot(DocumentSnapshot snap) { return $className(");

    if (fields.keys.contains('id')) {
      buffer.writeln("snap.id,");
    }
    for (var parameterName in fields.keys.where((element) => element != 'id')) {
      buffer
          .writeln("snap.get(\"$parameterName\") as ${fields[parameterName]},");
    }

    buffer.writeln(");}");
    return buffer.toString();
  }

  String _buildToDocument(String className, Map<String, dynamic> fields) {
    final buffer = StringBuffer();
    buffer.writeln("Map<String, Object> toDocument() { return {");

    for (var parameterName in fields.keys.where((element) => element != 'id')) {
      buffer.writeln("\"$parameterName\" : $parameterName,");
    }

    buffer.writeln("};}");
    return buffer.toString();
  }
}
