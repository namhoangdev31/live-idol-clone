# Live Idol Clone

**Voice Clone + VRM Avatar cho Livestream**

Hệ thống PoC kết hợp voice cloning (Coqui TTS) và 3D VRM avatar, xuất real-time video + audio vào OBS.

---

## 🎯 Tính Năng

✅ **Voice Cloning** - Clone giọng nói từ audio mẫu (5-10 giây)  
✅ **3D VRM Avatar** - Render avatar với lip-sync theo giọng  
✅ **OBS Integration** - Video (Window Capture) + Audio (VB-CABLE)  
✅ **Local Processing** - Chạy hoàn toàn offline trên Windows

---

## 📋 Yêu Cầu Hệ Thống

- Windows 10/11 (64-bit)
- RAM: 8GB+ (16GB khuyến nghị)
- GPU: Tùy chọn (4GB+ VRAM cho TTS nhanh hơn)
- Dung lượng: ~5GB
- **VB-CABLE** (tải miễn phí tại https://vb-audio.com/Cable/)

---

## � Sử Dụng (End Users)

### Cài Đặt

1. Tải `LiveIdolCloneInstaller.exe`
2. Chạy installer và làm theo hướng dẫn
3. Cài VB-CABLE khi được nhắc
4. Khởi động lại máy
5. Mở "Live Idol Clone" từ Start Menu

### Sử Dụng Ứng Dụng

1. **Khởi động** - Đợi backend khởi tạo (~10-15 giây)
2. **Kiểm tra** - Đảm bảo "Backend" và "TTS Engine" màu xanh
3. **Nhập text** - Gõ nội dung cần nói (tối đa 1000 ký tự)
4. **Click "Speak"** - Audio được tạo trong 2-10 giây
5. **Xem trong OBS** - Avatar sẽ nói với giọng đã clone

### Thiết Lập Voice Profile (Tùy Chọn)

Để clone giọng tốt hơn:

1. Vào: `C:\Program Files\LiveIdolClone\backend\voice_profiles\default\`
2. Thu âm 5-10 giây giọng nói rõ ràng (WAV, 16-bit, 22050 Hz)
3. Lưu thành `reference.wav`
4. Khởi động lại app

---

## 🎬 Cấu Hình OBS

### Video (Unity Window)

1. Thêm Source → **Window Capture**
2. Chọn window: `[VRMRenderer.exe]: Unity`
3. Điều chỉnh vị trí/kích thước

### Audio (Virtual Audio)

1. Thêm Source → **Audio Input Capture**
2. Device: `CABLE Output (VB-Audio Virtual Cable)`
3. Điều chỉnh volume trong mixer

### Test

1. Chạy Unity VRM Renderer
2. Chạy Live Idol Clone
3. Tạo speech
4. Kiểm tra OBS:
   - ✅ Thấy avatar animation
   - ✅ Nghe được audio đồng bộ

---

## 🛠️ Build Từ Source Code

### Quick Start (Tự Động)

```bash
# Trên macOS/Linux
./build_production.sh

# Trên Windows
build_all.bat
```

### Chi Tiết

Xem file **`COMPLETE_GUIDE.md`** để có hướng dẫn đầy đủ về:
- Cài đặt môi trường dev
- Build từng component
- Unity setup
- Tạo installer
- Troubleshooting

---

## ⚠️ Troubleshooting

### Backend không khởi động

- Check Python 3.10+ đã cài
- Check port 8000 không bị chiếm
- Chạy với quyền Administrator

### TTS chậm

- Dùng GPU (cần CUDA toolkit)
- Giảm độ dài text
- Chờ model load xong (lần đầu)

### OBS không có audio

1. Cài VB-CABLE
2. Khởi động lại máy
3. Set CABLE Output trong OBS
4. Khởi động lại OBS

### Unity không hiện

- Check Unity app đang chạy
- Refresh window list trong OBS
- Thử dùng Game Capture

---

## 📚 Documentation

| File | Mục Đích |
|------|----------|
| **COMPLETE_GUIDE.md** | Tài liệu đầy đủ (build, setup, troubleshoot) |
| **BUILD_AUTOMATION.md** | Hướng dẫn chạy script tự động |
| **backend/voice_profiles/default/README.md** | Setup voice profile |

---

## 🔒 Privacy & Consent

- Xử lý hoàn toàn local, không gửi data ra ngoài
- Chỉ clone giọng có sự đồng ý
- Voice profile lưu local, không upload
- Tuân thủ quy định về AI-generated content

---

## 🆘 Support

1. Xem mục Troubleshooting ở trên
2. Đọc `COMPLETE_GUIDE.md` để biết chi tiết
3. Check logs trong terminal/console
4. Tạo issue trên GitHub repository

---

## 🙏 Credits

- **Coqui TTS**: https://github.com/coqui-ai/TTS
- **UniVRM**: https://github.com/vrm-c/UniVRM
- **VB-CABLE**: https://vb-audio.com/Cable/
- **Django**: https://www.djangoproject.com/
- **Flutter**: https://flutter.dev/

---

**Dự án hoàn chỉnh và sẵn sàng cho production build!** 🚀

_Để build từ source code, xem `COMPLETE_GUIDE.md` hoặc chạy `./build_production.sh`_
