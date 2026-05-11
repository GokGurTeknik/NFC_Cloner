package com.example.nfc_cloner

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class HceService : HostApduService() {

    companion object {
        private const val TAG = "HceService"
        private const val PREF_NAME = "nfc_hce_prefs"
        private const val KEY_ACTIVE = "hce_active"
        private const val KEY_UID = "hce_uid"
        private const val KEY_HISTORICAL = "hce_historical_bytes"
        private const val KEY_HI_LAYER = "hce_hi_layer_response"

        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val SW_UNKNOWN = byteArrayOf(0x6F.toByte(), 0x00.toByte())
        private val SW_FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        val prefs = getSharedPreferences(PREF_NAME, MODE_PRIVATE)

        if (!prefs.getBoolean(KEY_ACTIVE, false)) {
            return SW_UNKNOWN
        }

        Log.d(TAG, "APDU alındı: ${commandApdu.toHex()}")

        // SELECT command (CLA=00, INS=A4)
        if (commandApdu.size >= 2 &&
            commandApdu[0] == 0x00.toByte() &&
            commandApdu[1] == 0xA4.toByte()
        ) {
            Log.d(TAG, "SELECT komutu — OK döndürülüyor")
            return SW_OK
        }

        // GET UID (FF CA 00 00 00)
        if (commandApdu.size >= 4 &&
            commandApdu[0] == 0xFF.toByte() &&
            commandApdu[1] == 0xCA.toByte() &&
            commandApdu[2] == 0x00.toByte()
        ) {
            val uid = prefs.getString(KEY_UID, null)
            if (uid != null) {
                Log.d(TAG, "UID isteği — $uid döndürülüyor")
                return hexToBytes(uid) + SW_OK
            }
            return SW_FILE_NOT_FOUND
        }

        // READ BINARY (CLA=00, INS=B0)
        if (commandApdu.size >= 4 &&
            commandApdu[0] == 0x00.toByte() &&
            commandApdu[1] == 0xB0.toByte()
        ) {
            val historical = prefs.getString(KEY_HISTORICAL, null)
            if (!historical.isNullOrEmpty()) {
                return hexToBytes(historical) + SW_OK
            }
            return SW_FILE_NOT_FOUND
        }

        // GET DATA — historical bytes / hi layer response
        if (commandApdu.size >= 2 &&
            commandApdu[0] == 0x80.toByte() &&
            commandApdu[1] == 0xCA.toByte()
        ) {
            val hiLayer = prefs.getString(KEY_HI_LAYER, null)
            if (!hiLayer.isNullOrEmpty()) {
                return hexToBytes(hiLayer) + SW_OK
            }
            return SW_FILE_NOT_FOUND
        }

        return SW_UNKNOWN
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "Deaktif edildi, sebep: $reason")
    }

    private fun ByteArray.toHex(): String = joinToString("") { "%02X".format(it) }

    private fun hexToBytes(hex: String): ByteArray {
        val clean = hex.replace(" ", "").replace(":", "")
        if (clean.length % 2 != 0) return ByteArray(0)
        return ByteArray(clean.length / 2) { i ->
            clean.substring(i * 2, i * 2 + 2).toInt(16).toByte()
        }
    }
}
