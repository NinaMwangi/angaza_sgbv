package app.angaza.sgbv

import android.content.Intent
import android.service.quicksettings.TileService

class SosTileService : TileService() {
    override fun onClick() {
        // Bring app to foreground, pass extra to auto-trigger SOS
        val i = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("sos", true)
        }
        startActivityAndCollapse(i) // collapses QS panel
    }
}
