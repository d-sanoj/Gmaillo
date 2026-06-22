import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        
        let textView = NSTextView()
        textView.autoresizingMask = [.width]
        textView.isRichText = true
        textView.importsGraphics = true
        textView.allowsImageEditing = true
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.backgroundColor = .clear
        textView.textStorage?.delegate = context.coordinator
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if !textView.attributedString().isEqual(to: attributedText) {
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.setAttributedString(attributedText)
            textView.selectedRanges = selectedRanges
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
        }
        
        func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
            DispatchQueue.main.async {
                self.parent.attributedText = NSAttributedString(attributedString: textStorage)
            }
        }
    }
}

extension NSTextView {
    @objc func toggleBulletedList(_ sender: Any?) {
        applyList(NSTextList(markerFormat: .init("{disc}"), options: 0))
    }
    
    @objc func toggleNumberedList(_ sender: Any?) {
        applyList(NSTextList(markerFormat: .init("{decimal}"), options: 0))
    }
    
    private func applyList(_ list: NSTextList) {
        guard let textStorage = textStorage else { return }
        let range = selectedRange()
        
        var hasList = false
        if range.location < textStorage.length {
            if let style = textStorage.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle {
                if !style.textLists.isEmpty {
                    hasList = true
                }
            }
        }
        
        textStorage.beginEditing()
        let fullRange = (textStorage.string as NSString).lineRange(for: range)
        
        textStorage.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, subrange, _ in
            let mutableStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            if hasList {
                mutableStyle.textLists = []
            } else {
                mutableStyle.textLists = [list]
            }
            
            textStorage.addAttribute(.paragraphStyle, value: mutableStyle, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    @objc func increaseIndent(_ sender: Any?) {
        adjustIndent(increase: true)
    }
    
    @objc func decreaseIndent(_ sender: Any?) {
        adjustIndent(increase: false)
    }
    
    private func adjustIndent(increase: Bool) {
        guard let textStorage = textStorage else { return }
        let range = selectedRange()
        let fullRange = (textStorage.string as NSString).lineRange(for: range)
        
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, subrange, _ in
            let mutableStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            
            let currentIndent = mutableStyle.headIndent
            let newIndent = increase ? currentIndent + 28.0 : max(0, currentIndent - 28.0)
            mutableStyle.headIndent = newIndent
            mutableStyle.firstLineHeadIndent = newIndent
            
            textStorage.addAttribute(.paragraphStyle, value: mutableStyle, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
}
