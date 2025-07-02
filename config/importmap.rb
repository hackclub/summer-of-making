# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"

pin "@tiptap/core", to: "@tiptap--core.js" # @2.12.0
pin "@tiptap/pm/commands", to: "@tiptap--pm--commands.js" # @2.12.0
pin "@tiptap/pm/keymap", to: "@tiptap--pm--keymap.js" # @2.12.0
pin "@tiptap/pm/model", to: "@tiptap--pm--model.js" # @2.12.0
pin "@tiptap/pm/schema-list", to: "@tiptap--pm--schema-list.js" # @2.12.0
pin "@tiptap/pm/state", to: "@tiptap--pm--state.js" # @2.12.0
pin "@tiptap/pm/transform", to: "@tiptap--pm--transform.js" # @2.12.0
pin "@tiptap/pm/view", to: "@tiptap--pm--view.js" # @2.12.0
pin "orderedmap" # @2.1.1
pin "prosemirror-commands" # @1.7.1
pin "prosemirror-keymap" # @1.2.3
pin "prosemirror-model" # @1.25.1
pin "prosemirror-schema-list" # @2.1.0
pin "prosemirror-state" # @1.4.3
pin "prosemirror-transform" # @1.10.4
pin "prosemirror-view" # @1.39.3
pin "w3c-keyname" # @2.2.8
pin "@tiptap/starter-kit", to: "@tiptap--starter-kit.js" # @2.12.0
pin "@tiptap/extension-blockquote", to: "@tiptap--extension-blockquote.js" # @2.12.0
pin "@tiptap/extension-bold", to: "@tiptap--extension-bold.js" # @2.12.0
pin "@tiptap/extension-bullet-list", to: "@tiptap--extension-bullet-list.js" # @2.12.0
pin "@tiptap/extension-code", to: "@tiptap--extension-code.js" # @2.12.0
pin "@tiptap/extension-code-block", to: "@tiptap--extension-code-block.js" # @2.12.0
pin "@tiptap/extension-document", to: "@tiptap--extension-document.js" # @2.12.0
pin "@tiptap/extension-dropcursor", to: "@tiptap--extension-dropcursor.js" # @2.12.0
pin "@tiptap/extension-gapcursor", to: "@tiptap--extension-gapcursor.js" # @2.12.0
pin "@tiptap/extension-hard-break", to: "@tiptap--extension-hard-break.js" # @2.12.0
pin "@tiptap/extension-heading", to: "@tiptap--extension-heading.js" # @2.12.0
pin "@tiptap/extension-history", to: "@tiptap--extension-history.js" # @2.12.0
pin "@tiptap/extension-horizontal-rule", to: "@tiptap--extension-horizontal-rule.js" # @2.12.0
pin "@tiptap/extension-italic", to: "@tiptap--extension-italic.js" # @2.12.0
pin "@tiptap/extension-list-item", to: "@tiptap--extension-list-item.js" # @2.12.0
pin "@tiptap/extension-ordered-list", to: "@tiptap--extension-ordered-list.js" # @2.12.0
pin "@tiptap/extension-paragraph", to: "@tiptap--extension-paragraph.js" # @2.12.0
pin "@tiptap/extension-strike", to: "@tiptap--extension-strike.js" # @2.12.0
pin "@tiptap/extension-text", to: "@tiptap--extension-text.js" # @2.12.0
pin "@tiptap/pm/dropcursor", to: "@tiptap--pm--dropcursor.js" # @2.12.0
pin "@tiptap/pm/gapcursor", to: "@tiptap--pm--gapcursor.js" # @2.12.0
pin "@tiptap/pm/history", to: "@tiptap--pm--history.js" # @2.12.0
pin "prosemirror-dropcursor" # @1.8.2
pin "prosemirror-gapcursor" # @1.3.2
pin "prosemirror-history" # @1.4.1
pin "rope-sequence" # @1.3.4
pin "@tiptap/extension-typography", to: "@tiptap--extension-typography.js" # @2.12.0
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin "howler" # @2.2.4
