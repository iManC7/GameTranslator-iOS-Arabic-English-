// SPDX-License-Identifier: AGPL-3.0-only
package com.gametranslator.gametranslator_mobile.tvinstall

import java.io.Closeable

/**
 * Kurulumu yarıda kesmek için. Ağ işleri bloklayan soketlerle yapılır; vazgeçildiğinde açık soket ve oturumlar
 * kapatılır, bekleyen okuma hemen hata verir ve iş [TvError.CANCELLED] ile biter.
 */
class Cancel {
    @Volatile
    var cancelled = false
        private set
    private val open = LinkedHashSet<Closeable>()

    fun cancel() {
        cancelled = true
        val toClose = synchronized(open) { open.toList().also { open.clear() } }
        for (item in toClose) runCatching { item.close() }
    }

    fun <T : Closeable> track(item: T): T {
        synchronized(open) { open.add(item) }
        if (cancelled) {
            runCatching { item.close() }
            throw TvInstallException(TvError.CANCELLED)
        }
        return item
    }

    fun untrack(item: Closeable) {
        synchronized(open) { open.remove(item) }
    }

    fun check() {
        if (cancelled) throw TvInstallException(TvError.CANCELLED)
    }

    /** Vazgeçilince erken uyanan bekleme. */
    fun sleep(millis: Long) {
        val end = System.currentTimeMillis() + millis
        while (true) {
            check()
            val left = end - System.currentTimeMillis()
            if (left <= 0) return
            Thread.sleep(minOf(left, 100))
        }
    }

    /** Vazgeçildiyse oluşan hata [TvError.CANCELLED] olur (kapatılan soketin verdiği hata yerine). */
    inline fun <T> guard(block: () -> T): T = try {
        block()
    } catch (error: TvInstallException) {
        if (cancelled) throw TvInstallException(TvError.CANCELLED) else throw error
    } catch (error: Exception) {
        if (cancelled) throw TvInstallException(TvError.CANCELLED) else throw error
    }

    companion object {
        val NONE = Cancel()
    }
}
