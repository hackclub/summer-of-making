# frozen_string_literal: true

module ShopItemsHelper
  def text_field_editable(item, field_name, display_prefix: "")
    editable(item, field_name, display_prefix, :text)
  end

  def number_field_editable(item, field_name, display_prefix: "")
    editable(item, field_name, display_prefix, :number)
  end

  def image_field_editable(item, field_name)
    editable(item, field_name, nil, :image)
  end

  def checkbox_field_editable(item, field_name, display_name: nil)
    editable(item, field_name, display_name || field_name.to_s.humanize, :checkbox)
  end

  private

  def editable(item, field_name, display_prefix = "", field_type)
    container_id = "item-#{item.id}-container-#{field_name}"

    style = "line-clamp-3 text-sm md:text-base 2xl:text-lg text-gray-600 break-words overflow-wrap-anywhere"
    style = "text-2xl" if field_name == :name

    html = content_tag(:div, id: container_id, class: "item-container") do
      safe_join([
                  content_tag(:div, class: "item", style: "display: flex; flex-direction: column;") do
                    tag = if field_type == :image
                            image_tag item.image.variant(:thumb) if item.image.attached?
                    elsif field_type == :checkbox
                            content_tag(:p, "#{display_prefix}: #{item.public_send(field_name) ? 'Yes' : 'No'}", class: style)
                    else
                            content_tag(:p, "#{display_prefix}#{item.public_send(field_name)}", class: style)
                    end

                    concat tag

                    admin_tool("m-0 my-auto px-1 py-0 ml-auto leading-none") do
                      button_tag "Edit #{field_name}", class: "edit text-xs"
                    end
                  end,

                  form_with(model: item, url: shop_item_path(item), scope: :shop_item,
                            html: { style: "display: none;" }) do |f|
                    case field_type
                    when :text
                      form_field = f.text_field(field_name, class: style)
                    when :number
                      form_field = f.number_field(field_name, step: 0.01, class: style)
                    when :image
                      form_field = f.file_field(field_name, class: style)
                    when :checkbox
                      form_field = f.check_box(field_name, class: "mr-2") + f.label(field_name, display_prefix)
                    else
                      raise NotImplementedError
                    end

                    safe_join([ form_field, f.submit ])
                  end
                ])
    end

    js = javascript_tag <<~JS
      document.addEventListener("DOMContentLoaded", () => {
        const container = document.getElementById("#{container_id}");
        if (!container) return;

        const row  = container.querySelector(".item");
        const form = container.querySelector("form");

        container.querySelector("button.edit").onclick = () => {
          row.style.display  = "none";
          form.style.display = "block";
        };

        form.onsubmit = (e) => {
          e.preventDefault();
          const data = new FormData(form);

          fetch("#{shop_item_path(item)}", {
            method: "PATCH",
            body: data,
            headers: {
              "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
              "Accept": "application/json"
            },
            credentials: "same-origin"
          }).then(() => window.location.reload());
        };
      });
    JS

    safe_join([ html, js ])
  end
end
