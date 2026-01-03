# 🚀 Build Tự Động - Quick Start

## Chạy Ngay

```bash
chmod +x build_production.sh
./build_production.sh
```

## Script Làm Gì?

✅ Check môi trường (Python, Flutter, disk)  
✅ Build Django backend (~10-15 phút)  
✅ Download TTS models (~2GB)  
✅ Tạo executable với PyInstaller  
✅ Copy files vào `installer/files/`  
⚠️ Flutter build (cần Windows)  
⚠️ Unity build (manual)  

## Kết Quả

```
build_output/
├── backend/          ✅ Backend executable
├── flutter/          ⚠️ Cần Windows
└── unity/            ⚠️ Manual step

installer/files/      ✅ Sẵn sàng cho Inno Setup
```

## Platform

| Platform | Backend | Flutter | Unity |
|----------|---------|---------|-------|
| macOS | ✅ | ❌ | ⚠️ Manual |
| Windows | ✅ | ✅ | ⚠️ Manual |

**Trên Windows**: Dùng `build_all.bat` thay vì script này.

## Sau Build

1. **Trên macOS**: Transfer `installer/files/` → Windows → Inno Setup
2. **Trên Windows**: Mở `setup.iss` → Compile → Nhận installer

## Troubleshooting

```bash
# Python not found
brew install python@3.10  # macOS

# Permission denied
chmod +x build_production.sh

# Disk space (cần ~10GB)
df -h
```

## Documentation

📚 **Chi tiết**: `COMPLETE_GUIDE.md`

---

**Script tự động 100% những gì có thể!** 🎉
