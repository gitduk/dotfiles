# Global Instructions

## Rust Projects
- After completing code changes, always run `cargo clippy` and fix any warnings before reporting done.

## CLI / Terminal
- 终端输入涉及中文/日文/韩文等 CJK 宽字符时，必须用支持 unicode-width 的 line editor（如 rustyline），不能用 raw stdin reader（BufReader::lines 等），否则光标位置会错位。
- CLI 交互式应用中，用户提交输入后等待响应期间，必须显示 thinking/loading 提示（如 dim 灰色的 "thinking..."），响应到达后清除。不要让用户面对空白等待。
