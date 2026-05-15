use flutter_rust_bridge::frb;
use whitenoise::markdown::{
    Alignment as WhitenoiseAlignment, AutolinkKind as WhitenoiseAutolinkKind,
    Block as WhitenoiseBlock, CodeBlockKind as WhitenoiseCodeBlockKind,
    Document as WhitenoiseDocument, Inline as WhitenoiseInline, ListItem as WhitenoiseListItem,
    ListKind as WhitenoiseListKind, NostrEntity as WhitenoiseNostrEntity,
    NostrHrp as WhitenoiseNostrHrp, TableCell as WhitenoiseTableCell,
};

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownDocument {
    pub blocks: Vec<MarkdownBlock>,
}

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MarkdownBlock {
    Paragraph {
        inlines: Vec<MarkdownInline>,
    },
    Heading {
        level: u8,
        inlines: Vec<MarkdownInline>,
    },
    ThematicBreak,
    CodeBlock {
        kind: MarkdownCodeBlockKind,
        info: String,
        content: String,
    },
    BlockQuote {
        blocks: Vec<MarkdownBlock>,
    },
    List {
        kind: MarkdownListKind,
        tight: bool,
        items: Vec<MarkdownListItem>,
    },
    Table {
        alignments: Vec<MarkdownAlignment>,
        header: Vec<MarkdownTableCell>,
        rows: Vec<Vec<MarkdownTableCell>>,
    },
    MathBlock {
        content: String,
    },
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkdownCodeBlockKind {
    Indented,
    Fenced,
}

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MarkdownListKind {
    /// `marker` is a single-character String: "-", "*", or "+".
    Bullet { marker: String },
    /// `delimiter` is a single-character String: "." or ")".
    Ordered { start: u32, delimiter: String },
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownListItem {
    pub blocks: Vec<MarkdownBlock>,
    /// `None` for plain bullets/ordered items, `Some(false)` for `[ ]`, `Some(true)` for `[x]`.
    pub checked: Option<bool>,
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkdownAlignment {
    None,
    Left,
    Center,
    Right,
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownTableCell {
    pub inlines: Vec<MarkdownInline>,
}

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MarkdownInline {
    Text {
        content: String,
    },
    SoftBreak,
    HardBreak,
    Code {
        content: String,
    },
    Emph {
        children: Vec<MarkdownInline>,
    },
    Strong {
        children: Vec<MarkdownInline>,
    },
    Strikethrough {
        children: Vec<MarkdownInline>,
    },
    Link {
        dest: String,
        title: Option<String>,
        children: Vec<MarkdownInline>,
    },
    Image {
        dest: String,
        title: Option<String>,
        alt: Vec<MarkdownInline>,
    },
    Autolink {
        url: String,
        kind: MarkdownAutolinkKind,
    },
    Math {
        content: String,
    },
    NostrMention {
        entity: MarkdownNostrEntity,
    },
    NostrUri {
        entity: MarkdownNostrEntity,
    },
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkdownAutolinkKind {
    Uri,
    Email,
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownNostrEntity {
    pub hrp: MarkdownNostrHrp,
    pub bech32: String,
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkdownNostrHrp {
    Npub,
    Note,
    Nevent,
    Nprofile,
    Naddr,
    Nrelay,
}

impl From<&WhitenoiseDocument> for MarkdownDocument {
    fn from(doc: &WhitenoiseDocument) -> Self {
        Self {
            blocks: doc.blocks.iter().map(MarkdownBlock::from).collect(),
        }
    }
}

impl From<WhitenoiseDocument> for MarkdownDocument {
    fn from(doc: WhitenoiseDocument) -> Self {
        (&doc).into()
    }
}

impl From<&WhitenoiseBlock> for MarkdownBlock {
    fn from(block: &WhitenoiseBlock) -> Self {
        match block {
            WhitenoiseBlock::Paragraph { inlines } => Self::Paragraph {
                inlines: inlines.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseBlock::Heading { level, inlines } => Self::Heading {
                level: *level,
                inlines: inlines.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseBlock::ThematicBreak => Self::ThematicBreak,
            WhitenoiseBlock::CodeBlock {
                kind,
                info,
                content,
            } => Self::CodeBlock {
                kind: (*kind).into(),
                info: info.clone(),
                content: content.clone(),
            },
            WhitenoiseBlock::BlockQuote { blocks } => Self::BlockQuote {
                blocks: blocks.iter().map(MarkdownBlock::from).collect(),
            },
            WhitenoiseBlock::List { kind, tight, items } => Self::List {
                kind: kind.into(),
                tight: *tight,
                items: items.iter().map(MarkdownListItem::from).collect(),
            },
            WhitenoiseBlock::Table {
                alignments,
                header,
                rows,
            } => Self::Table {
                alignments: alignments.iter().map(|a| (*a).into()).collect(),
                header: header.iter().map(MarkdownTableCell::from).collect(),
                rows: rows
                    .iter()
                    .map(|row| row.iter().map(MarkdownTableCell::from).collect())
                    .collect(),
            },
            WhitenoiseBlock::MathBlock { content } => Self::MathBlock {
                content: content.clone(),
            },
        }
    }
}

impl From<WhitenoiseCodeBlockKind> for MarkdownCodeBlockKind {
    fn from(kind: WhitenoiseCodeBlockKind) -> Self {
        match kind {
            WhitenoiseCodeBlockKind::Indented => Self::Indented,
            WhitenoiseCodeBlockKind::Fenced => Self::Fenced,
        }
    }
}

impl From<&WhitenoiseListKind> for MarkdownListKind {
    fn from(kind: &WhitenoiseListKind) -> Self {
        match *kind {
            WhitenoiseListKind::Bullet { marker } => Self::Bullet {
                marker: (marker as char).to_string(),
            },
            WhitenoiseListKind::Ordered { start, delimiter } => Self::Ordered {
                start,
                delimiter: (delimiter as char).to_string(),
            },
        }
    }
}

impl From<&WhitenoiseListItem> for MarkdownListItem {
    fn from(item: &WhitenoiseListItem) -> Self {
        Self {
            blocks: item.blocks.iter().map(MarkdownBlock::from).collect(),
            checked: item.checked,
        }
    }
}

impl From<WhitenoiseAlignment> for MarkdownAlignment {
    fn from(alignment: WhitenoiseAlignment) -> Self {
        match alignment {
            WhitenoiseAlignment::None => Self::None,
            WhitenoiseAlignment::Left => Self::Left,
            WhitenoiseAlignment::Center => Self::Center,
            WhitenoiseAlignment::Right => Self::Right,
        }
    }
}

impl From<&WhitenoiseTableCell> for MarkdownTableCell {
    fn from(cell: &WhitenoiseTableCell) -> Self {
        Self {
            inlines: cell.inlines.iter().map(MarkdownInline::from).collect(),
        }
    }
}

impl From<&WhitenoiseInline> for MarkdownInline {
    fn from(inline: &WhitenoiseInline) -> Self {
        match inline {
            WhitenoiseInline::Text(s) => Self::Text { content: s.clone() },
            WhitenoiseInline::SoftBreak => Self::SoftBreak,
            WhitenoiseInline::HardBreak => Self::HardBreak,
            WhitenoiseInline::Code(s) => Self::Code { content: s.clone() },
            WhitenoiseInline::Emph(children) => Self::Emph {
                children: children.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseInline::Strong(children) => Self::Strong {
                children: children.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseInline::Strikethrough(children) => Self::Strikethrough {
                children: children.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseInline::Link {
                dest,
                title,
                children,
            } => Self::Link {
                dest: dest.clone(),
                title: title.clone(),
                children: children.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseInline::Image { dest, title, alt } => Self::Image {
                dest: dest.clone(),
                title: title.clone(),
                alt: alt.iter().map(MarkdownInline::from).collect(),
            },
            WhitenoiseInline::Autolink { url, kind } => Self::Autolink {
                url: url.clone(),
                kind: (*kind).into(),
            },
            WhitenoiseInline::Math(s) => Self::Math { content: s.clone() },
            WhitenoiseInline::NostrMention(entity) => Self::NostrMention {
                entity: entity.into(),
            },
            WhitenoiseInline::NostrUri(entity) => Self::NostrUri {
                entity: entity.into(),
            },
        }
    }
}

impl From<WhitenoiseAutolinkKind> for MarkdownAutolinkKind {
    fn from(kind: WhitenoiseAutolinkKind) -> Self {
        match kind {
            WhitenoiseAutolinkKind::Uri => Self::Uri,
            WhitenoiseAutolinkKind::Email => Self::Email,
        }
    }
}

impl From<&WhitenoiseNostrEntity> for MarkdownNostrEntity {
    fn from(entity: &WhitenoiseNostrEntity) -> Self {
        Self {
            hrp: entity.hrp.into(),
            bech32: entity.bech32.clone(),
        }
    }
}

impl From<WhitenoiseNostrHrp> for MarkdownNostrHrp {
    fn from(hrp: WhitenoiseNostrHrp) -> Self {
        match hrp {
            WhitenoiseNostrHrp::Npub => Self::Npub,
            WhitenoiseNostrHrp::Note => Self::Note,
            WhitenoiseNostrHrp::Nevent => Self::Nevent,
            WhitenoiseNostrHrp::Nprofile => Self::Nprofile,
            WhitenoiseNostrHrp::Naddr => Self::Naddr,
            WhitenoiseNostrHrp::Nrelay => Self::Nrelay,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_document() {
        let doc = WhitenoiseDocument::default();
        let bridged: MarkdownDocument = (&doc).into();
        assert_eq!(bridged, MarkdownDocument { blocks: vec![] });
    }

    #[test]
    fn paragraph_with_text() {
        let doc = whitenoise::markdown::parse("hello world");
        let bridged: MarkdownDocument = (&doc).into();
        assert_eq!(
            bridged,
            MarkdownDocument {
                blocks: vec![MarkdownBlock::Paragraph {
                    inlines: vec![MarkdownInline::Text {
                        content: "hello world".to_string(),
                    }],
                }],
            }
        );
    }

    #[test]
    fn heading_levels() {
        let doc = whitenoise::markdown::parse("## hi");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::Heading { level, .. } => assert_eq!(*level, 2),
            other => panic!("expected heading, got {other:?}"),
        }
    }

    #[test]
    fn thematic_break() {
        let doc = whitenoise::markdown::parse("---");
        let bridged: MarkdownDocument = (&doc).into();
        assert!(matches!(bridged.blocks[0], MarkdownBlock::ThematicBreak));
    }

    #[test]
    fn fenced_code_block() {
        let doc = whitenoise::markdown::parse("```rust\nfn main() {}\n```");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::CodeBlock {
                kind,
                info,
                content,
            } => {
                assert_eq!(*kind, MarkdownCodeBlockKind::Fenced);
                assert_eq!(info, "rust");
                assert!(content.contains("fn main"));
            }
            other => panic!("expected code block, got {other:?}"),
        }
    }

    #[test]
    fn indented_code_block() {
        let doc = whitenoise::markdown::parse("    code");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::CodeBlock { kind, .. } => {
                assert_eq!(*kind, MarkdownCodeBlockKind::Indented);
            }
            other => panic!("expected code block, got {other:?}"),
        }
    }

    #[test]
    fn blockquote() {
        let doc = whitenoise::markdown::parse("> hi");
        let bridged: MarkdownDocument = (&doc).into();
        assert!(matches!(
            bridged.blocks[0],
            MarkdownBlock::BlockQuote { .. }
        ));
    }

    #[test]
    fn bullet_list_marker_dash() {
        let doc = whitenoise::markdown::parse("- one\n- two");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::List { kind, items, .. } => {
                assert!(matches!(kind, MarkdownListKind::Bullet { marker } if marker == "-"));
                assert_eq!(items.len(), 2);
                assert!(items[0].checked.is_none());
            }
            other => panic!("expected list, got {other:?}"),
        }
    }

    #[test]
    fn ordered_list_with_start() {
        let doc = whitenoise::markdown::parse("3. one\n4. two");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::List { kind, .. } => match kind {
                MarkdownListKind::Ordered { start, delimiter } => {
                    assert_eq!(*start, 3);
                    assert_eq!(delimiter, ".");
                }
                other => panic!("expected ordered list, got {other:?}"),
            },
            other => panic!("expected list, got {other:?}"),
        }
    }

    #[test]
    fn task_list_checked_and_unchecked() {
        let doc = whitenoise::markdown::parse("- [ ] todo\n- [x] done");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::List { items, .. } => {
                assert_eq!(items[0].checked, Some(false));
                assert_eq!(items[1].checked, Some(true));
            }
            other => panic!("expected list, got {other:?}"),
        }
    }

    #[test]
    fn table_with_alignment() {
        let doc = whitenoise::markdown::parse("| a | b |\n| :- | -: |\n| 1 | 2 |");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::Table {
                alignments,
                header,
                rows,
            } => {
                assert_eq!(alignments[0], MarkdownAlignment::Left);
                assert_eq!(alignments[1], MarkdownAlignment::Right);
                assert_eq!(header.len(), 2);
                assert_eq!(rows.len(), 1);
            }
            other => panic!("expected table, got {other:?}"),
        }
    }

    #[test]
    fn alignment_variants() {
        assert_eq!(
            MarkdownAlignment::from(WhitenoiseAlignment::None),
            MarkdownAlignment::None
        );
        assert_eq!(
            MarkdownAlignment::from(WhitenoiseAlignment::Left),
            MarkdownAlignment::Left
        );
        assert_eq!(
            MarkdownAlignment::from(WhitenoiseAlignment::Center),
            MarkdownAlignment::Center
        );
        assert_eq!(
            MarkdownAlignment::from(WhitenoiseAlignment::Right),
            MarkdownAlignment::Right
        );
    }

    #[test]
    fn math_block() {
        let doc = whitenoise::markdown::parse("$$\nE=mc^2\n$$");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::MathBlock { content } => assert!(content.contains("E=mc^2")),
            other => panic!("expected math block, got {other:?}"),
        }
    }

    #[test]
    fn inline_emphasis_strong_strikethrough_code() {
        let doc = whitenoise::markdown::parse("*a* **b** ~~c~~ `d`");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        let kinds: Vec<&str> = inlines
            .iter()
            .map(|i| match i {
                MarkdownInline::Emph { .. } => "emph",
                MarkdownInline::Strong { .. } => "strong",
                MarkdownInline::Strikethrough { .. } => "strike",
                MarkdownInline::Code { .. } => "code",
                MarkdownInline::Text { .. } => "text",
                _ => "other",
            })
            .collect();
        assert!(kinds.contains(&"emph"));
        assert!(kinds.contains(&"strong"));
        assert!(kinds.contains(&"strike"));
        assert!(kinds.contains(&"code"));
    }

    #[test]
    fn inline_link() {
        let doc = whitenoise::markdown::parse("[text](https://example.com \"title\")");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        match &inlines[0] {
            MarkdownInline::Link {
                dest,
                title,
                children,
            } => {
                assert_eq!(dest, "https://example.com");
                assert_eq!(title.as_deref(), Some("title"));
                assert_eq!(children.len(), 1);
            }
            other => panic!("expected link, got {other:?}"),
        }
    }

    #[test]
    fn inline_image() {
        let doc = whitenoise::markdown::parse("![alt](https://example.com/a.png)");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        match &inlines[0] {
            MarkdownInline::Image { dest, alt, .. } => {
                assert_eq!(dest, "https://example.com/a.png");
                assert_eq!(alt.len(), 1);
            }
            other => panic!("expected image, got {other:?}"),
        }
    }

    #[test]
    fn autolink_uri_and_email() {
        let doc = whitenoise::markdown::parse("<https://example.com> <a@b.com>");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        let mut saw_uri = false;
        let mut saw_email = false;
        for inline in inlines {
            if let MarkdownInline::Autolink { kind, .. } = inline {
                match kind {
                    MarkdownAutolinkKind::Uri => saw_uri = true,
                    MarkdownAutolinkKind::Email => saw_email = true,
                }
            }
        }
        assert!(saw_uri);
        assert!(saw_email);
    }

    #[test]
    fn soft_and_hard_breaks() {
        let doc = whitenoise::markdown::parse("a\nb  \nc");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        let has_soft = inlines
            .iter()
            .any(|i| matches!(i, MarkdownInline::SoftBreak));
        let has_hard = inlines
            .iter()
            .any(|i| matches!(i, MarkdownInline::HardBreak));
        assert!(has_soft);
        assert!(has_hard);
    }

    #[test]
    fn inline_math() {
        let doc = whitenoise::markdown::parse("$E=mc^2$");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        assert!(
            inlines
                .iter()
                .any(|i| matches!(i, MarkdownInline::Math { .. }))
        );
    }

    #[test]
    fn nostr_uri_and_mention() {
        let doc = whitenoise::markdown::parse(
            "nostr:npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s @npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s",
        );
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        let mut saw_uri = false;
        let mut saw_mention = false;
        for inline in inlines {
            match inline {
                MarkdownInline::NostrUri { entity } => {
                    saw_uri = true;
                    assert_eq!(entity.hrp, MarkdownNostrHrp::Npub);
                    assert!(entity.bech32.starts_with("npub1"));
                }
                MarkdownInline::NostrMention { entity } => {
                    saw_mention = true;
                    assert_eq!(entity.hrp, MarkdownNostrHrp::Npub);
                }
                _ => {}
            }
        }
        assert!(saw_uri);
        assert!(saw_mention);
    }

    #[test]
    fn nostr_hrp_variants() {
        for (hrp, expected) in [
            (WhitenoiseNostrHrp::Npub, MarkdownNostrHrp::Npub),
            (WhitenoiseNostrHrp::Note, MarkdownNostrHrp::Note),
            (WhitenoiseNostrHrp::Nevent, MarkdownNostrHrp::Nevent),
            (WhitenoiseNostrHrp::Nprofile, MarkdownNostrHrp::Nprofile),
            (WhitenoiseNostrHrp::Naddr, MarkdownNostrHrp::Naddr),
            (WhitenoiseNostrHrp::Nrelay, MarkdownNostrHrp::Nrelay),
        ] {
            assert_eq!(MarkdownNostrHrp::from(hrp), expected);
        }
    }

    #[test]
    fn nested_blockquote_and_list() {
        let doc = whitenoise::markdown::parse("> - one\n> - two");
        let bridged: MarkdownDocument = (&doc).into();
        match &bridged.blocks[0] {
            MarkdownBlock::BlockQuote { blocks } => {
                assert!(matches!(blocks[0], MarkdownBlock::List { .. }));
            }
            other => panic!("expected blockquote, got {other:?}"),
        }
    }

    #[test]
    fn deeply_nested_emphasis() {
        let doc = whitenoise::markdown::parse("***bold italic***");
        let bridged: MarkdownDocument = (&doc).into();
        let MarkdownBlock::Paragraph { inlines } = &bridged.blocks[0] else {
            panic!("expected paragraph");
        };
        assert!(matches!(
            inlines[0],
            MarkdownInline::Emph { .. } | MarkdownInline::Strong { .. }
        ));
    }
}
