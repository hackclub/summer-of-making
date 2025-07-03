namespace :readme do
  desc "Run README checks on projects and show results (DRY RUN)"
  task check: :environment do |task, args|
    limit = ENV.fetch("LIMIT", 10).to_i
    puts "🔍 DRY RUN: Previewing README checks on #{limit} projects..."
    puts "=" * 70

    # Find projects with readme links
    projects_to_check = Project.where.not(readme_link: [ nil, "" ])
                               .limit(limit)

    if projects_to_check.empty?
      puts "❌ No projects found with README links!"
      exit
    end

    puts "Found #{projects_to_check.count} projects to preview"
    puts ""

    results = { would_be_missing: 0, has_content: 0, fetch_failed: 0 }

    projects_to_check.each_with_index do |project, index|
      puts "[#{index + 1}/#{projects_to_check.count}] Project #{project.id}: #{project.title}"
      puts "📎 README URL: #{project.readme_link}"

      begin
        # Fetch the README content
        response = Faraday.get(project.readme_link)

        if response.success?
          content = response.body

          # Handle encoding issues
          begin
            content = content.force_encoding("UTF-8")
            unless content.valid_encoding?
              # Try to convert from common encodings
              [ "UTF-16", "UTF-16LE", "UTF-16BE", "ISO-8859-1" ].each do |encoding|
                begin
                  content = response.body.force_encoding(encoding).encode("UTF-8")
                  break if content.valid_encoding?
                rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
                  next
                end
              end
            end

            # If still invalid, clean it up
            unless content.valid_encoding?
              content = content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
            end
          rescue => encoding_error
            puts "⚠️ ENCODING ERROR: #{encoding_error.message}"
            puts "📝 Using raw content (may have display issues)"
            content = response.body.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
          end

          # Test our pre-check logic
          dummy_check = ReadmeCheck.new(content: content, readme_link: project.readme_link)
          is_minimal = dummy_check.send(:content_is_missing_or_minimal?)

          if is_minimal
            puts "❌ PRE-CHECK: Would be marked as MISSING (minimal/empty content)"
            puts "📝 Content preview: #{content.strip[0..100]}#{'...' if content.length > 100}"
            results[:would_be_missing] += 1
          else
            puts "✅ PRE-CHECK: Has substantial content - running AI classification..."

            # Show content preview
            lines = content.strip.split("\n").reject(&:blank?)
            preview_lines = lines.first(3)
            puts "📝 Content preview:"
            preview_lines.each { |line| puts "   #{line.strip[0..80]}#{'...' if line.length > 80}" }
            puts "   ... (#{lines.length - 3} more lines)" if lines.length > 3

            # Run AI classification (dry run - no database updates)
            ai_result = perform_ai_classification_dry_run(content)

            if ai_result[:success]
              decision_emoji = case ai_result[:decision]
              when "specific" then "🎉"
              when "templated" then "📋"
              when "ai_generated" then "🤖"
              when "missing" then "❌"
              else "❓"
              end

              puts "#{decision_emoji} AI DECISION: #{ai_result[:decision].upcase}"
              puts "🧠 AI Reasoning: #{ai_result[:reason]}" if ai_result[:reason].present?

              # Update results counter
              if results[ai_result[:decision].to_sym].nil?
                results[ai_result[:decision].to_sym] = 0
              end
              results[ai_result[:decision].to_sym] += 1
            else
              puts "💥 AI FAILED: #{ai_result[:error]}"
              results[:ai_failed] ||= 0
              results[:ai_failed] += 1
            end

            results[:has_content] += 1
          end

          # Show content type
          content_type = response.headers["content-type"]
          puts "📄 Content-Type: #{content_type}" if content_type

        else
          puts "💥 FETCH FAILED: HTTP #{response.status}"
          puts "📝 Error: #{response.body[0..100]}#{'...' if response.body.length > 100}"
          results[:fetch_failed] += 1
        end

      rescue => e
        puts "💥 ERROR: #{e.message}"
        results[:fetch_failed] += 1
      end

      puts ""
      puts "-" * 70
      puts ""
    end

    puts "📊 DRY RUN SUMMARY:"
    puts "  ✅ Total processed:                  #{results[:has_content] || 0}"
    puts "  ❌ Pre-check marked as MISSING:      #{results[:would_be_missing] || 0}"
    puts "  💥 Fetch failed:                     #{results[:fetch_failed] || 0}"
    puts ""
    puts "📈 AI CLASSIFICATION RESULTS:"
    puts "  🎉 Specific:                         #{results[:specific] || 0}"
    puts "  📋 Templated:                        #{results[:templated] || 0}"
    puts "  🤖 AI Generated:                     #{results[:ai_generated] || 0}"
    puts "  ❌ Missing (AI marked):              #{results[:missing] || 0}"
    puts "  💥 AI Failed:                        #{results[:ai_failed] || 0}"
    puts ""
    puts "Total previewed: #{projects_to_check.count}"
    puts ""
    puts "💡 This was a DRY RUN - no data was saved to the database"
  end

  def perform_ai_classification_dry_run(content)
    prompt = <<~PROMPT
      Review this README content and classify it based on whether you can understand what the project actually does.

      Respond with one of:
      - `TEMPLATED: reason` - You cannot tell what this project does (generic templates, boilerplate, single headers, create-react-app defaults, etc.)
      - `AI_GENERATED: reason` - Content appears to be AI-generated. Things like "clone https://github.com/username/repo.git" or heavy use of emoji is a good indicator. Also talking a lot about generic things.
      - `SPECIFIC: reason` - You can understand what this project specifically does from the description
      - `MISSING: reason` - The README is missing a description of what the project does or is empty

      The key question: Can you tell what this project is and what it does from reading this README?

      Note: Just having a project name is not enough for SPECIFIC - there needs to be actual description of functionality.

      No yapping. Just respond back in the correct format. Also, don't include any formatting or markdown, only use plain text.

      README content:
      #{content.split("\n").map { |line| "> #{line}" }.join("\n")}
    PROMPT

    begin
      approved_outputs = %w[TEMPLATED AI_GENERATED SPECIFIC MISSING]
      result = GroqService.call(prompt)

      decision = result.split(":").first.strip.upcase
      reason = result.split(":")[1..-1].join(":").strip if result.include?(":")

      if approved_outputs.include?(decision)
        {
          success: true,
          decision: decision.downcase,
          reason: reason
        }
      else
        {
          success: false,
          error: "Unexpected AI decision format: #{decision}"
        }
      end
    rescue => e
      {
        success: false,
        error: "AI service error: #{e.message}"
      }
    end
  end

  desc "Show README check statistics"
  task stats: :environment do
    puts "📊 README Check Statistics"
    puts "=" * 40

    total_projects = Project.where.not(readme_link: [ nil, "" ]).count
    total_checks = ReadmeCheck.where(status: :success).count

    puts "Total projects with README links: #{total_projects}"
    puts "Total successful checks: #{total_checks}"
    puts ""

    if total_checks > 0
      ReadmeCheck.where(status: :success).group(:decision).count.each do |decision, count|
        percentage = (count.to_f / total_checks * 100).round(1)
        emoji = case decision
        when "specific" then "🎉"
        when "templated" then "📋"
        when "ai_generated" then "🤖"
        when "missing" then "❌"
        else "❓"
        end
        puts "#{emoji} #{decision.humanize.ljust(12)}: #{count.to_s.rjust(4)} (#{percentage}%)"
      end
    end

    failed_checks = ReadmeCheck.where(status: :failure).count
    if failed_checks > 0
      puts ""
      puts "💥 Failed checks: #{failed_checks}"
    end
  end
end
