import 'package:flutter/material.dart';
import 'package:participant_pishgaman/constans.dart';

class ButtonComponent extends StatelessWidget {
  final Widget? child;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color color;
  final BorderSide borderSide;
  final bool enabled;
  final bool loading;
  final double width;
  final double height;
  final String text;

  const ButtonComponent(
      {super.key, required this.onPressed,
      this.child,
      this.borderRadius = 16,
      this.borderSide = BorderSide.none,
      this.enabled = true,
      this.loading = false,
      this.color = Constants.primaryColor,
      this.width = 250,
      this.height = 55,
      this.text = ""});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.white,
              onTap: !loading && enabled ? onPressed : null,
              child: loading
                  ? Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            color != Colors.white
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )
                  : (child != null)
                      ? Center(child: child)
                      : Center(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Constants.primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 20),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
