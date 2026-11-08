# Kế hoạch đánh giá Kaset sau khi hoàn thiện tính năng

Ngày lập: 2026-11-08. Trạng thái: kế hoạch, chưa thực hiện đợt review này.

## Mục tiêu và phạm vi

Đánh giá xem app có đủ ổn định để dùng hằng ngày, các luồng chính có dễ sử dụng,
và chỗ nào đáng tối ưu dựa trên số đo thực tế. Giữ nguyên phạm vi tính năng trong
đợt đánh giá; chỉ bổ sung chức năng khi một hành trình sử dụng cho thấy nhu cầu rõ
ràng. Không đặt mục tiêu không thể kiểm chứng như “đã tối ưu hết”.

Ưu tiên theo thứ tự: bảo vệ phiên đăng nhập và dữ liệu → phát đúng nội dung, đúng
trạng thái → thao tác phản hồi tốt → giảm tài nguyên → cải thiện chi tiết giao diện.

## Hiện trạng đã xác minh

| Bản app | Vị trí | Danh tính | Ghi chú |
| --- | --- | --- | --- |
| Bản cài mang tên YouTube | `/Applications/YouTube.app` | `com.sertacozercan.Kaset` | Phiên bản `1.0.0-custom`, ký ad-hoc; timestamp `2026-11-06T19:34:00Z` |
| Bản cài trùng mang tên YouTube | `~/Applications/Youtube.app` | `com.sertacozercan.Kaset` | Cùng phiên bản và timestamp với bản trên |
| Bản debug vừa kiểm tra | `.build/app/Kaset.app` | `com.sertacozercan.Kaset.debug` | Tên Kaset, phiên bản `1.0.0-custom`, ký ad-hoc; timestamp `2026-11-08T10:38:05Z` |

Các bundle cùng ghi commit `3b35506`, nhưng checkout đang có thay đổi chưa commit.
Vì vậy commit trong Info.plist chưa đủ để xác định toàn bộ source tạo ra binary.
Không suy ra cấu hình biên dịch của hai bản cài chỉ từ bundle ID.

Đã kiểm tra ở phiên làm việc trước: build/package debug thành công; 8 test trong
`PlaybackArbiterTests` pass; bật/tắt toàn màn hình bằng nút và F, thoát bằng Esc,
pause/resume bằng Space hoạt động trên một video. Đây là smoke test có phạm vi
hẹp, chưa phải kết quả nghiệm thu toàn app.

Chưa xác minh trực tiếp được kết quả tìm kiếm Spotlight. Tên tìm bản cài là
YouTube; tên bundle debug là Kaset. Chưa thay thế hay xóa bản cài nào.

## Giai đoạn 1 — Chốt đúng bản dùng để đánh giá

1. Ghi nhận source hiện tại, diff chưa commit, phiên bản toolchain, macOS và máy
   thử. Phân biệt thay đổi có sẵn với thay đổi của đợt review; không tự gom hay
   commit phần việc chưa được xác định là thuộc đợt này.
2. Chọn tên dùng hằng ngày: YouTube hoặc Kaset. Chọn một vị trí cài chính để tránh
   mở nhầm bản; lập phương án xử lý bản trùng, giữ khả năng quay lại bản cũ trước
   khi thay thế. Việc chuẩn hóa tên và cài đặt là bước thực hiện sau kế hoạch.
3. Tạo một bản ứng viên dùng hằng ngày và ghi nhận mã nguồn, cấu hình, checksum
   executable, timestamp. Tách bản debug dùng chẩn đoán khỏi bản đo hiệu năng.
4. Kiểm tra riêng đường đăng nhập của bản release: debug dùng file cookie, còn
   release có đường Keychain khác. Không coi việc debug đăng nhập thành công là
   bằng chứng release sẽ hoạt động. Không thử ghi đè phiên thật để kiểm tra.
5. Mở app từ Finder và Spotlight, xác nhận tên, icon, About/version và binary đang
   chạy đều đúng. Kiểm tra URL scheme có mở đúng bản khi có nhiều bản cài.
6. Giữ mô hình cập nhật thủ công theo ADR-0042. Bản dùng cá nhân không bắt buộc có
   quy trình phân phối công khai; nếu muốn phát hành cho người khác thì đánh giá
   thêm Developer ID, notarization và cách cập nhật trong phạm vi riêng.

Đầu ra: bảng nhận diện bản thử và hướng dẫn mở/cập nhật/quay lại bản cũ. Chỉ bắt
đầu so sánh hiệu năng sau khi đã xác định đúng binary và cấu hình.

## Giai đoạn 2 — Review source theo mức độ rủi ro

Review cả kiến trúc hiện hữu lẫn diff mới, ưu tiên các đường chạy dưới đây. Đọc
code thực tế để xác minh, dùng tài liệu kiến trúc và ADR làm bối cảnh; ghi nhận khi
tài liệu không còn khớp source.

| Vùng | Câu hỏi review và bằng chứng cần tìm |
| --- | --- |
| `KasetApp`, `MainWindow`, điều hướng | Ai sở hữu trạng thái cửa sổ? Shortcut có chạy hai lần? Đóng/mở cửa sổ, fullscreen và pop-out có giữ cùng một phiên phát? |
| `PlayerService`, `YouTubePlayerService`, `PlaybackArbiter` | Lệnh mới có thắng callback cũ? Chuyển Music/YouTube có dừng nguồn trước? Pause, seek, next và autoplay có thống nhất giữa native và WebView? |
| WebView và bridge JavaScript | Có rò handler, timer, event monitor hoặc WebView? Có bỏ qua message thuộc document/media generation cũ? Web content process chết có phục hồi đúng ý định người dùng? |
| Auth, cookie, tài khoản | Không lộ credential; cache/state được phân tách theo account; 401/403 và session loss không gây vòng lặp hay xóa dữ liệu ngoài ý muốn; kiểm tra khác biệt debug/release. |
| API client, parser, cache | Request trùng, pagination, hủy tác vụ, retry, invalidation sau thay đổi dữ liệu; API có sẵn được dùng thay cho WebView; parser có bằng chứng response thực tế. |
| SwiftUI và concurrency | Task ownership, cancellation, stale response, single-flight load, MainActor bị chặn; identity ổn định; cập nhật progress không khiến cả màn hình dựng lại liên tục. |
| Hình ảnh và danh sách dài | Downsampling, giới hạn cache, prefetch, tải thêm và hủy tải; có thực sự giảm việc khi phần tử ra ngoài màn hình không? |
| UX, localization, accessibility | Label, focus, bàn phím, tooltip, lỗi/rỗng/loading, catalog và mirror đồng bộ, fallback macOS 15.4. |

Chạy baseline CLI theo `AGENTS.md`: build, bộ non-UI test, lint và kiểm tra format
bằng phiên bản SwiftFormat được CI ghim. Không định dạng hàng loạt source có sẵn
chỉ để làm review. Phân biệt lỗi baseline với lỗi do thay đổi mới.

Mỗi finding cần có file/dòng, điều kiện kích hoạt, ảnh hưởng người dùng, bằng
chứng, hướng sửa nhỏ nhất và cách xác nhận sau sửa. Không tính một vấn đề phong
cách là lỗi hiệu năng nếu chưa có số đo.

Dùng `autoreview` sau khi các test tập trung hoàn thành. Review checkout chưa
commit dùng `--mode local` và không truyền `--source-context-file`. Sau khi commit
các thay đổi thuộc đợt sửa, chạy branch review theo đúng lệnh trong `AGENTS.md`,
xác định base từ PR, chỉ dùng main khi thực sự chưa có PR. Không chạy review cùng
lúc với test hay đo hiệu năng. Xác minh từng finding, ghi lý do chấp nhận/bác bỏ;
sau sửa do review, chạy lại test tập trung và review một lần.

Đầu ra: danh sách finding được xác minh, bản đồ test còn thiếu và các rủi ro chưa
được kiểm chứng. Chưa triển khai refactor rộng chỉ vì class/file lớn.

## Giai đoạn 3 — Kiểm tra các hành trình sử dụng thực tế

Mỗi kịch bản ghi trạng thái đầu, thao tác, kết quả mong đợi, kết quả thực tế và
bản app. Đánh giá cả thành công tác vụ, số thao tác, phản hồi và khả năng phục hồi.

| Hành trình | Tình huống cần thử | Tiêu chí |
| --- | --- | --- |
| Mở app hằng ngày | Spotlight, khởi động nguội/ấm, khôi phục cửa sổ | Mở đúng bản; nhanh có giao diện dùng được; không skeleton vô hạn |
| Tìm và bắt đầu xem/nghe | Search, Home, playlist/channel, Back rồi quay lại | Không mất truy vấn/vị trí cuộn vô cớ; chọn nội dung có phản hồi rõ |
| Điều khiển playback | Play/pause, seek, next/back, thao tác liên tiếp | Phát đúng mục; không tự phát lại sau pause; thanh tiến trình theo kịp |
| Chuyển kiểu xem | Inline ↔ fullscreen ↔ floating; F/Esc/⌘P, double-click, resize | Không mở cửa sổ thừa, âm thanh kép, mất hình hoặc nhảy tiến độ |
| Chuyển nguồn | Music ↔ YouTube khi đang phát, đang tải, đang pause | Chỉ nguồn được chọn có quyền phát; metadata và media key theo đúng nguồn |
| Dùng nền | Đóng cửa sổ bằng nút đỏ/⌘W, mở lại, hide, minimize | Hành vi theo thiết kế hiện có; không nhân bản player hoặc mất trạng thái |
| Thư viện và tài khoản | Dữ liệu có sẵn, đổi account/guest, trạng thái rỗng | Không lẫn nội dung giữa tài khoản; trạng thái dễ hiểu và nhất quán |
| Gián đoạn | Mạng chậm/mất mạng rồi trở lại, sleep/wake, đổi đầu ra âm thanh | Không treo; thông báo có hướng xử lý; không tự đổi ý định pause/play |
| Thao tác macOS | Media key, menu, focus ô tìm kiếm, shortcut chuẩn | Phím không bị player chiếm khi đang nhập chữ; menu và trạng thái khớp |
| Khả năng tiếp cận | Chỉ dùng bàn phím, VoiceOver, cửa sổ nhỏ, tăng cỡ chữ nếu hỗ trợ | Điều khiển có tên, focus thấy được, nội dung/nút không bị che |

Phạm vi chính: macOS hiện tại trên máy người dùng; xác minh fallback macOS 15.4
và macOS 26 khi có môi trường. Những nền tảng/đầu ra âm thanh chưa có thiết bị thử
phải được đánh dấu chưa kiểm chứng, không suy ra pass.

UI test tự động chỉ chạy sau khi xin phép theo `AGENTS.md`, vì sẽ chiếm desktop.
Đăng nhập mới dùng môi trường/tài khoản thử phù hợp; không xóa app data hiện tại.
Like, subscribe, playlist mutation, sign-out, gửi Ask và live request thay đổi
account chỉ được thử trong phạm vi đã được người dùng cho phép cụ thể. Khi chưa
có quyền, dùng test offline/mock và ghi rõ giới hạn bằng chứng.

Đầu ra: ma trận pass/fail/chưa thử, các lỗi có thể tái hiện và ghi chú những điểm
gây bối rối dù app không báo lỗi kỹ thuật.

## Giai đoạn 4 — Đo hiệu năng và độ ổn định

Không dùng debug để kết luận hiệu năng release. Dùng cấu hình tối ưu đã xác minh
auth hoạt động và môi trường thử được tách an toàn; ghi CPU, RAM, macOS, độ phân
giải video, nội dung thử, mạng và trạng thái cache. Chạy từng phép đo độc lập,
không build/test/review đồng thời.

| Phép đo | Cách lấy baseline | Cách đánh giá |
| --- | --- | --- |
| Startup | 10 lần mở nguội theo cùng điều kiện cache và 10 lần mở ấm; tách cửa sổ phản hồi được khỏi Home tải xong | Báo median và khoảng dao động; tách thời gian mạng, auth và render |
| Bắt đầu phát | Đo từ click đến xác nhận playback cho cùng nội dung; tách quảng cáo và buffering | Không gộp độ trễ YouTube/mạng thành lỗi UI; ghi rõ mẫu và ngoại lệ |
| Phản hồi điều khiển | Ít nhất 30 mẫu mỗi thao tác thường dùng; đo click/phím đến phản hồi UI và đến xác nhận player | Báo median/p95; mục tiêu ban đầu phản hồi UI p95 ≤ 100 ms trên máy thử |
| Search và tải danh sách | Đo input/debounce/request/render, warm/cold cache, request trùng, phân trang | Đảm bảo truy vấn cũ không ghi đè mới; giảm request mà vẫn giữ dữ liệu đúng |
| Cuộn và chuyển màn hình | Lặp cùng hành trình dài, artwork nhiều, resize, fullscreen | Xác định hitch/main-thread work; cải thiện điểm giật có thể tái hiện |
| CPU và năng lượng | Idle 5 phút, paused, audio, video, nền/fullscreen | Tính cả app và các process WebKit; tìm polling/animation thừa, không chỉ nhìn process chính |
| Bộ nhớ | Phiên 60 phút; 30 vòng mở/đóng màn hình hoặc chuyển kiểu xem; so các điểm cùng trạng thái sau warm-up | Phân biệt cache có giới hạn với leak; điều tra tăng liên tục và object/timer còn sống |
| Độ bền | Dùng liên tục 2 giờ và dùng hằng ngày 3–7 ngày | Không crash/hang tái hiện được; không âm thanh kép hoặc mất quyền điều khiển |

Các mốc trên là thiết kế phép đo và mục tiêu đề xuất, chưa phải số liệu app đạt
được. Chốt ngân sách startup, CPU và RAM sau baseline thay vì đặt một mức MB/%
tùy ý cho mọi video và mọi máy. Không đánh đổi phiên đăng nhập hoặc độ đúng của
playback chỉ để giảm một chỉ số.

Với vấn đề timing/lifecycle: thêm trace tạm tại `NSTemporaryDirectory()`, flush
mỗi dòng, tái hiện, sửa theo dữ liệu, đo lại cùng điều kiện rồi gỡ trace. Dùng
profiling để tìm CPU/allocation/main-thread hotspot khi cần. Không ghi cookie,
token, header auth, payload tài khoản hay lịch sử xem vào trace/report.

Đầu ra: bảng baseline, trace/profile đã lọc dữ liệu nhạy cảm, bottleneck có bằng
chứng và bảng so sánh trước/sau cho từng tối ưu.

## Giai đoạn 5 — Chọn cải thiện trải nghiệm và sửa theo đợt nhỏ

Đây là các giả thuyết cần kiểm chứng qua giai đoạn 3–4, chưa phải kết luận lỗi:

1. **Vào app và xem tiếp nhanh hơn:** một bản cài dễ tìm; khôi phục đúng nội dung
   và tiến độ; giảm thao tác để tiếp tục việc đang làm.
2. **Điều khiển nhất quán:** một ý nghĩa cho play/pause/fullscreen/PiP ở nút,
   menu và shortcut; focus không gây hành vi bất ngờ; trạng thái chuyển tiếp rõ.
3. **Chờ dễ hiểu:** phản hồi ngay khi click, phân biệt đang tải/buffering/hết
   phiên/mất mạng; có cách thử lại mà giữ ngữ cảnh.
4. **Duyệt nội dung ít gián đoạn:** giữ vị trí cuộn và query; ảnh tải đúng kích
   thước; tải thêm không làm nhảy bố cục; cache không hiển thị nhầm account.
5. **Dùng lâu ít hao tài nguyên:** giảm công việc khi pause/ẩn cửa sổ nếu không
   cần thiết; kiểm tra timer, polling, animation và WebView thừa bằng số đo.

Ưu tiên sửa theo tác động × tần suất, cân nhắc công sức và nguy cơ regression:

- P0: credential/data exposure, mất hoặc trộn dữ liệu tài khoản.
- P1: crash/hang, không phát được, âm thanh kép, sai video/tiến độ, mất điều khiển.
- P2: chậm hoặc giật thường xuyên, hao tài nguyên được đo, mất ngữ cảnh điều hướng.
- P3: chi tiết hiển thị và tiện ích có ảnh hưởng nhỏ.

Mỗi đợt sửa tập trung một nhóm nguyên nhân: ghi bằng chứng → sửa tối thiểu → test
hồi quy có giá trị → kiểm tra runtime liên quan → đo lại → review. Ghi ADR nếu
thay đổi thiết kế đáng kể. Không thêm dependency hoặc viết lại kiến trúc khi chưa
chứng minh được lợi ích. Giữ lại kết quả không cải thiện để tránh lặp lại thử nghiệm.

## Tiêu chí kết thúc và bàn giao

- Một bản ứng viên có nguồn gốc rõ ràng, mở đúng từ Finder/Spotlight và có cách
  quay lại bản cũ; hành vi auth của cấu hình dùng hằng ngày đã được kiểm tra.
- Build, non-UI tests và lint/format phù hợp với phần thay đổi đều pass; các check
  chưa chạy, lỗi baseline và phạm vi chưa có máy thử được ghi rõ.
- Không còn P0/P1 đã xác minh; lỗi P2/P3 còn lại có tác động, lý do hoãn và bước
  tiếp theo. Không coi không tìm thấy lỗi là chứng minh không còn lỗi.
- Các hành trình playback chính pass trên bản ứng viên cuối; mỗi tối ưu có số đo
  trước/sau, không chỉ có cảm nhận hoặc kết quả trên bản debug.
- Hoàn tất phiên đo 2 giờ và thời gian dùng thật 3–7 ngày; ghi sự cố và cách tái
  hiện. Nếu thay đổi binary trong giai đoạn này, ghi phiên bản và kiểm tra lại các
  hành trình chịu ảnh hưởng.
- Báo cáo cuối gồm: bản nào được thử, test và lệnh review đã chạy, finding chấp
  nhận/bác bỏ cùng lý do, kết quả đo, giới hạn, cách cài/mở/cập nhật và backlog.

Thứ tự triển khai: chốt bản → baseline/review → thử hành trình → profiling → sửa
theo mức ảnh hưởng → nghiệm thu lại bản cuối → theo dõi dùng hằng ngày. Giai đoạn
dùng thật kéo dài theo lịch; các giai đoạn khác chốt công sức sau khi thấy baseline.

## Tài liệu đối chiếu

- [Quy tắc repo](../AGENTS.md)
- [Testing](testing.md)
- [Kiến trúc và hiệu năng](architecture.md#performance-guidelines)
- [Playback](playback.md)
- [YouTube](youtube.md)
- [Các lỗi đã gặp và cách đo](common-bug-patterns.md)
- [Cập nhật bản dùng cá nhân](adr/0042-manual-updates-for-personal-builds.md)
