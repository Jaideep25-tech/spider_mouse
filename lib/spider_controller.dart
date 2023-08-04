import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class SpiderController {
  final StateMachineController _stateMachineController;
  late SMIInput<double> _speedInput;
  late SMIInput<double> _turnInput;
  late SMIInput<double> _rotateInput;
  late SMITrigger _leftClick;
  late SMITrigger _rightClick;

  SpiderController(this._stateMachineController) {
    _speedInput = _stateMachineController.findInput('Speed')!;
    _turnInput = _stateMachineController.findInput('Turn')!;
    _rotateInput = _stateMachineController.findInput('Rotate')!;
    _leftClick =
        _stateMachineController.findInput<bool>('LeftClick') as SMITrigger;
    _rightClick =
        _stateMachineController.findInput<bool>('RightClick')! as SMITrigger;
  }

  Offset spiderPosition = Offset.zero;
  Offset targetPosition = Offset.zero;
  double _targetRotation = 0;
  double _rotation = 0;

  double get rotation => _rotation;

  Offset _direction = Offset.zero;

  double get dx => spiderPosition.dx;
  double get dy => spiderPosition.dy;

  static const double _maxMovementSpeed = 300.0;
  double _movementSpeed = 0;
  static const double _maxRotationSpeed = 4;
  double _turnSpeed = 0;

  void leftClick() => _leftClick.fire();

  void rightClick() => _rightClick.fire();

  void update(double dt) {
    final difference = targetPosition - spiderPosition;
    final distance = difference.distance;
    if (distance == 0) {
      _resetValues();
      return; // exit early
    }
    _direction = difference / distance;

    _calculateRotation(dt);

    _targetRotation = atan2(_direction.dx, -_direction.dy);
    final rotationDifference = _targetRotation - _rotation;
    if (rotationDifference > pi / 2) {
      return;
    }

    _calculatePosition(dt, distance);
  }

  void _calculateRotation(double dt) {
    _targetRotation = atan2(_direction.dx, -_direction.dy);
    final rotationDifference = _targetRotation - _rotation;

    final currentRotationValue = _rotateInput.value;
    final targetRotationValue = rotationDifference / pi * 100;

    if ((currentRotationValue - targetRotationValue).abs() < 5) {
      _rotateInput.value = 0;
    } else {
      if (currentRotationValue > targetRotationValue) {
        final newRotation = currentRotationValue - (1000 * dt);
        _rotateInput.value = newRotation;
      } else {
        final newRotation = currentRotationValue + (1000 * dt);
        _rotateInput.value = newRotation;
      }
    }

    // Ramp down the speed if we are close to the correct rotation
    if (rotationDifference.abs() < 0.1) {
      var rotationPercentage = _turnSpeed / _maxRotationSpeed * 100;
      rotationPercentage = clampDouble(rotationPercentage, 0, 100);
      if (_turnSpeed < 0) {
        _turnInput.value = 0;
        _turnSpeed = 0;
        return;
      }

      if (rotationPercentage >= 0) {
        _turnSpeed -= 0.1;
        _turnSpeed = _turnSpeed.clamp(0, _maxRotationSpeed);
        _turnInput.value = rotationPercentage;
      }
      return;
    }

    // Resolves the issue of the spider rotating the long way around
    // to face the target.
    if (rotationDifference > pi) {
      _rotation += 2 * pi;
    } else if (rotationDifference < -pi) {
      _rotation -= 2 * pi;
    }

    final rotationPercentage = _turnSpeed / _maxRotationSpeed * 100;
    _turnInput.value = rotationPercentage;

    if (_targetRotation > _rotation) {
      _rotation += _turnSpeed * dt;
    } else {
      _rotation -= _turnSpeed * dt;
    }

    _turnSpeed += rotationDifference.abs();
    _turnSpeed = _turnSpeed.clamp(0, min(_turnSpeed, _maxRotationSpeed));
  }

  void _calculatePosition(double dt, double distance) {
    _speedInput.value = (_movementSpeed * 1.5) / _maxMovementSpeed * 100;

    // POSITION
    if (distance < 0.1) {
      _movementSpeed = 0;
      return; // exit early
    }
    _movementSpeed += max(distance, 1);
    _movementSpeed =
        _movementSpeed.clamp(0, min(distance * 2, _maxMovementSpeed));

    spiderPosition += _direction * dt * _movementSpeed;
  }

  void _resetValues() {
    _turnInput.value = 0;
    _speedInput.value = 0;
    _movementSpeed = 0;
    _turnSpeed = 0;
  }
}
