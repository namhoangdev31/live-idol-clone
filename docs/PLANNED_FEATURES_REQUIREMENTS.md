# 📋 Tài liệu Yêu cầu Tính năng Chi tiết (Detailed Feature Requirements)

Tài liệu này đi sâu vào phân tích kỹ thuật, kiến trúc và luồng xử lý cho 4 tính năng cốt lõi: Lip Sync, Voice Cloning, Chat Integration và Animation System.

---

## 1. 🔄 Lip Sync (Đồng bộ Khẩu hình Thời gian thực)

### 1.1 Phân tích Kỹ thuật

Hệ thống cần chuyển đổi luồng âm thanh (Audio Stream) từ TTS thành chuyển động miệng (Viseme) của nhân vật VRM. Thách thức lớn nhất là độ trễ (latency) và sự tự nhiên của chuyển động.

### 1.2 Kiến trúc Đề xuất

- **Input**: Audio Buffer (PCM data) từ tiến trình TTS.
- **Process**:
  1. **Audio Analysis**: Sử dụng thuật toán phân tích quang phổ (FFT) hoặc thư viện chuyên dụng (uLipSync / OVRLipSync) để xác định âm tố (phoneme).
  2. **Mapping**: Ánh xạ Phoneme -> Viseme (A, I, U, E, O).
  3. **Smoothing**: Áp dụng bộ lọc (Low-pass filter) để chuyển động blendshape mượt mà, tránh bị giật (jitter).
- **Output**: Giá trị BlendShape [0.0 - 1.0] cho VRM Avatar.

### 1.3 Yêu cầu Chi tiết

- **Độ trễ (Latency)**: < 50ms từ khi âm thanh phát ra đến khi miệng cử động.
- **Micro-Expression**: Ngoài miệng, cần rung nhẹ cơ mặt hoặc mắt để tạo cảm giác thực tế khi nói to.
- **Cấu hình**:
  - `Smoothness`: Độ mượt (giảm độ nảy nhưng tăng trễ nhẹ).
  - `Gain`: Độ mở rộng của miệng theo âm lượng.
- **Công nghệ**:
  - **Unity**: Sử dụng `uLipSync` (Open Source) tích hợp sẵn hỗ trợ VRM.
  - **Backend**: Gửi audio raw data qua WebSocket hoặc Shared Memory để Unity xử lý trực tiếp.

---

## 2. 🔄 Voice Cloning (Nhân bản Giọng nói - Custom Voice)

### 2.1 Phân tích Kỹ thuật

Sử dụng khả năng fine-tuning hoặc zero-shot cloning của XTTS v2 để tạo giọng nói mới từ mẫu âm thanh ngắn. Cần xử lý vấn đề về tài nguyên phần cứng vì training rất nặng.

### 2.2 Quy trình Xử lý (Workflow)

1. **Data Ingestion**:
    - Upload file âm thanh (WAV/MP3).
    - Yêu cầu tối thiểu: 6 giây (Zero-shot) hoặc 1-5 phút (Fine-tuning).
    - Sample Rate: Tự động convert về 22050Hz hoặc 24000Hz.
2. **Preprocessing**:
    - **Denoise**: Loại bỏ tạp âm nền (sử dụng thư viện như `demucs` hoặc `noise-reduce`).
    - **Trim**: Cắt bỏ khoảng lặng đầu/cuối.
    - **Transcription**: Dùng Whisper để tạo text tương ứng với audio (cần thiết cho Fine-tuning tốt hơn).
3. **Training Management**:
    - Chạy training trên tiến trình riêng biệt (Background Worker).
    - Tạm dừng các tác vụ TTS inference khác để dồn VRAM cho training (nếu chạy local GPU đơn lẻ).
4. **Inference**:
    - Load file `.pth` (checkpoint) và `config.json` mới tạo.
    - Test giọng ngay trên giao diện.

### 2.3 Thách thức & Giải pháp

- **VRAM OOM (Out of Memory)**: Tự động kiểm tra VRAM khả dụng. Nếu < 6GB, cảnh báo người dùng hoặc chuyển sang chế độ CPU (chậm).
- **Chất lượng**: Tích hợp công cụ đánh giá độ tương đồng (Similarity Score) để người dùng biết mẫu audio có đạt chuẩn không.

---

## 3. 🔄 Chat Integration (Tích hợp & Phản hồi Thông minh)

### 3.1 Phân tích Kỹ thuật

Kết nối với các nền tảng livestream (TikTok/Shopee) vốn không có API public chính thống, đòi hỏi sử dụng các thư viện giả lập Client hoặc WebSocket sniffing.

### 3.2 Kiến trúc Module "Listener"

- **TikTokLive**: Sử dụng thư viện Python `TikTokLive` (kết nối qua room ID, không cần login credential).
- **Shopee Live**: Cần nghiên cứu API nội bộ (Private API) hoặc dùng Headless Browser (Selenium/Puppeteer) để bắt event.

### 3.3 Logic Xử lý Thông minh (The "Brain")

1. **Event Queue (Hàng đợi Ưu tiên)**:
    - **Priority 1 (Cao nhất)**: Donate/Gift (Cần phản hồi ngay lập tức + Animation cảm ơn).
    - **Priority 2**: Câu hỏi cụ thể (keyword match: "chào", "hát", "mấy tuổi").
    - **Priority 3**: Bình luận ngẫu nhiên (chọn lọc để đọc nếu rảnh).
2. **Context Memory**:
    - Lưu giữ 5-10 câu hội thoại gần nhất để AI (LLM) hiểu ngữ cảnh.
    - Tránh lặp lại câu trả lời cho cùng một người trong thời gian ngắn (Spam filter).
3. **Reaction Mapping**:
    - Keyword "vui quá" -> Trigger Animation `Happy`.
    - Keyword "buồn quá" -> Trigger Animation `Sad`.
    - Gift "Hoa hồng" -> Trigger Animation `Heart_Hand`.

---

## 4. 🔄 Animation System (Hệ thống Hoạt ảnh Phức tạp)

### 4.1 Phân tích Kỹ thuật

Hệ thống Animation cần linh hoạt, cho phép trộn (blend) giữa các lớp chuyển động khác nhau (ví dụ: vừa đi vừa vẫy tay, vừa nói vừa cười).

### 4.2 Thiết kế Animator Controller (Unity)

- **Base Layer**: Chứa chuyển động toàn thân (Idle, Walking, Sitting).
- **Gesture Layer (Upper Body)**: Mask từ hông trở lên. Chứa các hành động: Vẫy tay, Chỉ tay, Thả tim.
  - Sử dụng `AvatarMask` để không ảnh hưởng chân/hông.
- **Face Layer (Additive)**: Điều khiển BlendShape khuôn mặt (Mắt cười, Chớp mắt, Mở miệng).
  - LipSync sẽ đè (override) hoặc cộng (additive) vào layer này.

### 4.3 Giao thức Điều khiển (API Protocol)

Tạo chuẩn JSON cho lệnh Animation gửi từ Backend -> Unity:

```json
{
  "command": "play_animation",
  "data": {
    "name": "Wave_Hand",
    "layer": "Gesture",
    "fade_in": 0.25,        // Thời gian chuyển (seconds)
    "duration": 2.0,        // Thời gian diễn hoạt (nếu loop=false)
    "weight": 1.0,          // Cường độ action
    "expression": "Smile"   // Biểu cảm đi kèm (tùy chọn)
  }
}
```

### 4.4 Tính năng Mở rộng: Idle ngẫu nhiên

- Thay vì 1 pose Idle cứng nhắc, hệ thống sẽ có danh sách "Idle Actions" (vuốt tóc, nghiêng đầu, đổi chân trụ).
- Script `RandomIdleReactions` sẽ random chạy các action này mỗi 10-15s khi không có lệnh nào khác, giúp Avatar "sống động" hơn.
