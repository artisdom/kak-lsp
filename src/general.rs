use context::*;
use languageserver_types::notification::Notification;
use languageserver_types::request::Request;
use languageserver_types::*;
use std::process;
use toml;
use types::*;
use url::Url;

pub fn initialize(root_path: &str, meta: &EditorMeta, ctx: &mut Context) {
    let params = InitializeParams {
        capabilities: ClientCapabilities {
            workspace: Some(WorkspaceClientCapabilities::default()),
            text_document: Some(TextDocumentClientCapabilities {
                synchronization: None,
                completion: Some(CompletionCapability {
                    dynamic_registration: None,
                    completion_item: Some(CompletionItemCapability {
                        snippet_support: None,
                        commit_characters_support: None,
                        documentation_format: None,
                    }),
                }),
                hover: None,
                signature_help: None,
                references: None,
                document_highlight: None,
                document_symbol: None,
                formatting: None,
                range_formatting: None,
                on_type_formatting: None,
                definition: None,
                code_action: None,
                code_lens: None,
                document_link: None,
                rename: None,
            }),
            experimental: None,
        },
        initialization_options: None,
        process_id: Some(process::id().into()),
        root_uri: Some(Url::parse(&format!("file://{}", root_path)).unwrap()),
        root_path: Some(root_path.to_string()),
        trace: Some(TraceOption::Off),
    };

    let id = ctx.next_request_id();
    ctx.response_waitlist.insert(
        id.clone(),
        (
            meta.clone(),
            request::Initialize::METHOD.into(),
            toml::Value::Table(toml::value::Table::default()),
        ),
    );
    ctx.call(id, request::Initialize::METHOD.into(), params);
}

pub fn exit(_params: EditorParams, _meta: &EditorMeta, ctx: &mut Context) {
    // NOTE we can't use Params::None because it's serialized as Value::Array([])
    let params: Option<u8> = None;
    ctx.notify(notification::Exit::METHOD.into(), params);
    ctx.lang_srv_poison_tx
        .send(())
        .expect("Failed to poison language server");
    ctx.controller_poison_tx
        .send(())
        .expect("Failed to poison controller");
}
