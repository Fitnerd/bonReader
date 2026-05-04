package de.enno.bonreader

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Verhindert Screenshots und Screen-Recording sowie das Vorschaubild
        // im App-Switcher. Schuetzt sensible Finanzdaten (Betraege, Budgets,
        // Bon-Inhalte).
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
