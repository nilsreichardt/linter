// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Prefer defining constructors instead of static methods to create instances.';

const _details = r'''

**PREFER** defining constructors instead of static methods to create instances.

In most cases, it makes more sense to use a named constructor rather than a
static method because it makes instantiation clearer.

**BAD:**
```dart
class Point {
  num x, y;
  Point(this.x, this.y);
  static Point polar(num theta, num radius) {
    return Point(radius * math.cos(theta),
        radius * math.sin(theta));
  }
}
```

**GOOD:**
```dart
class Point {
  num x, y;
  Point(this.x, this.y);
  Point.polar(num theta, num radius)
      : x = radius * math.cos(theta),
        y = radius * math.sin(theta);
}
```
''';

bool _hasNewInvocation(DartType returnType, FunctionBody body) {
  bool isInstanceCreationExpression(AstNode node) =>
      node is InstanceCreationExpression && node.staticType == returnType;

  return DartTypeUtilities.traverseNodesInDFS(body)
      .any(isInstanceCreationExpression);
}

class PreferConstructorsInsteadOfStaticMethods extends LintRule {
  PreferConstructorsInsteadOfStaticMethods()
      : super(
            name: 'prefer_constructors_over_static_methods',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var returnType = node.returnType?.type;
    var parent = node.parent;
    if (node.isStatic &&
        parent is ClassOrMixinDeclaration &&
        returnType is InterfaceType &&
        parent.typeParameters == null &&
        node.typeParameters == null) {
      var declaredElement = parent.declaredElement;
      if (declaredElement != null) {
        var interfaceType = declaredElement.thisType;
        if (!context.typeSystem.isAssignableTo(returnType, interfaceType)) {
          return;
        }
        if (_hasNewInvocation(returnType, node.body)) {
          rule.reportLint(node.name);
        }
      }
    }
  }
}
