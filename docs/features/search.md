# Search Feature

## Overview
Pencarian berita mengandalkan kinerja tinggi dan efisien.

### 1. SearchCubit
- Menggunakan arsitektur `Paginator` untuk meraup _Lazy Loaded Articles_.
- Mengimplementasikan `debounce` 300ms–500ms pada parameter `onQueryChanged` untuk menyelamatkan Limit API dan beban Server (di handle via bloc/cubit stream filter).
- Memisahkan state *Initial*, *Loading*, *Loaded*, *Empty*, dan *Error* dengan presisi.

### 2. Search History
- (TODO) Rencana integrasi dengan `SharedPreferences` menggunakan `SearchHistoryDataSource` untuk melacak `List<String>` kueri favorit yang pernah dimasukkan secara luring untuk *quick-access*.
