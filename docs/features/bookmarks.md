# Bookmarks & Detail Feature

## Overview
Modul bookmark dan artikel bertujuan untuk memberikan UX responsif dan reaktif.

### 1. BookmarkCubit
- Mengelola state koleksi bookmark _News_.
- Diatur agar mendukung **Optimistic Updating** untuk menjamin respon seketika kepada User ketika mereka mengetuk ikon bendera _bookmark_.
- Status perubahan (_Revert_) diimplementasikan jika server mengembalikan error _Network Failure_ pada saat proses penyimpanan sinkronisasi lanjutan.

### 2. ArticleDetailCubit
- Berbagi state dan terhubung langsung menggunakan arsitektur use-case `ToggleBookmarkUseCase`.
- Integrasi ke *WebView* / *Html Renderer* (tergantung spesifikasi UI nantinya) untuk pembacaan isi konten penuh dalam markdown/HTML format dari raw _response_ Content.
