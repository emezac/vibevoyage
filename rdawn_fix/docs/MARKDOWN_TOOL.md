# Markdown Tool Documentation

The rdawn MarkdownTool provides comprehensive markdown editing capabilities with AI assistance and seamless integration with the Marksmith gem for GitHub-style editing in Rails applications.

## Overview

The MarkdownTool combines AI-powered content generation with practical markdown editing features, template creation, and validation. It's designed to work with or without the Marksmith gem, providing fallback options for environments where Marksmith isn't available.

## Features

### 🤖 AI-Powered Features
- **Content Generation**: Create markdown content with AI assistance
- **Intelligent Editing**: Edit existing content while preserving style
- **Improvement Suggestions**: Get AI-powered suggestions for content enhancement
- **Style Customization**: Generate content in different writing styles (technical, conversational, academic, creative, professional)

### 📝 Markdown Processing
- **Template Creation**: Generate various document templates (README, blog posts, API docs, articles)
- **Format Validation**: Check markdown syntax and structure
- **HTML Conversion**: Convert markdown to HTML with GitHub-style rendering
- **Table of Contents**: Generate TOC in multiple styles (bullet, numbered, links)
- **Batch Processing**: Process multiple markdown files simultaneously

### 🚀 Marksmith Integration
- **Form Field Generation**: Create Marksmith-compatible form fields for Rails
- **GitHub-Style Editing**: Leverage Marksmith's toolbar and preview features
- **File Upload Support**: Integrate with ActiveStorage for file handling
- **Fallback Support**: Graceful degradation when Marksmith is not available

## Installation

### Basic Setup

```ruby
# Add to your Gemfile
gem 'rdawn'

# Install
bundle install
```

### With Marksmith Integration

```ruby
# Add to your Gemfile
gem 'rdawn'
gem 'marksmith'
gem 'commonmarker'

# Install
bundle install
```

For Rails applications with Marksmith:

```bash
# Add JavaScript package
yarn add @avo-hq/marksmith

# Or with importmaps
bin/importmap pin @avo-hq/marksmith
```

## Usage

### Basic Usage

```ruby
require 'rdawn'

# Create the markdown tool
markdown_tool = Rdawn::Tools::MarkdownTool.new(api_key: ENV['OPENAI_API_KEY'])

# Generate content
result = markdown_tool.generate_markdown(
  prompt: "How to set up a Ruby on Rails application",
  style: 'technical',
  length: 'medium',
  model: 'gpt-4o-mini'
)

puts result[:markdown]
```

### AI-Powered Content Generation

```ruby
# Generate with different styles
styles = ['technical', 'conversational', 'academic', 'creative', 'professional']
lengths = ['short', 'medium', 'long']

result = markdown_tool.generate_markdown(
  prompt: "Introduction to machine learning",
  style: 'technical',
  length: 'medium',
  model: 'gpt-4o-mini'
)

# Result includes:
# - :markdown - The generated content
# - :word_count - Number of words
# - :style - Writing style used
# - :length - Content length
# - :model - AI model used
# - :generated_at - Timestamp
```

### Content Editing

```ruby
# Edit existing content
original_content = "# My Article\n\nThis is basic content."

edit_result = markdown_tool.edit_markdown(
  markdown: original_content,
  instructions: "Make this more engaging and add code examples",
  model: 'gpt-4o-mini',
  preserve_style: true
)

puts edit_result[:edited_markdown]
```

### Template Creation

```ruby
# Create different types of templates
template_types = ['readme', 'blog_post', 'api_docs', 'article', 'documentation']

readme_template = markdown_tool.create_template(
  type: 'readme',
  title: 'My Awesome Project',
  author: 'John Developer',
  tags: ['ruby', 'rails', 'api']
)

blog_template = markdown_tool.create_template(
  type: 'blog_post',
  title: 'Getting Started with Rails',
  author: 'Jane Writer',
  tags: ['rails', 'tutorial', 'beginner']
)
```

### Validation and Formatting

```ruby
# Validate markdown syntax
validation = markdown_tool.validate_markdown(
  markdown: content,
  strict: true
)

if validation[:valid]
  puts "✅ Markdown is valid"
else
  puts "❌ Issues found:"
  validation[:issues].each do |issue|
    puts "  - #{issue[:type]}: #{issue[:message]}"
  end
end

# Format markdown
formatted = markdown_tool.format_markdown(
  markdown: content,
  style: 'standard',
  line_length: 80
)
```

### Table of Contents Generation

```ruby
# Generate TOC in different styles
toc_bullet = markdown_tool.generate_toc(
  markdown: content,
  max_depth: 3,
  style: 'bullet'
)

toc_numbered = markdown_tool.generate_toc(
  markdown: content,
  max_depth: 3,
  style: 'numbered'
)

toc_links = markdown_tool.generate_toc(
  markdown: content,
  max_depth: 3,
  style: 'links'
)
```

### HTML Conversion

```ruby
# Convert to HTML with GitHub styling
html_result = markdown_tool.markdown_to_html(
  markdown: content,
  github_style: true,
  syntax_highlighting: true
)

puts html_result[:html]
```

### AI-Powered Suggestions

```ruby
# Get improvement suggestions
suggestions = markdown_tool.suggest_improvements(
  markdown: content,
  focus: 'readability',  # 'readability', 'structure', 'grammar', 'seo', 'accessibility'
  model: 'gpt-4o-mini'
)

suggestions[:suggestions].each do |suggestion|
  puts "📂 #{suggestion[:category]}"
  suggestion[:items].each do |item|
    puts "  • #{item}"
  end
end
```

## Marksmith Integration

### Rails Form Integration

```ruby
# Create Marksmith-compatible form fields
field_config = markdown_tool.create_marksmith_field(
  field_name: 'blog_content',
  initial_content: '',
  placeholder: 'Write your blog post...'
)

# Use in Rails views
<%= field_config[:form_helper] %>
```

### Full Rails Setup

1. **Add assets to your layout:**

```erb
<!-- app/views/layouts/application.html.erb -->
<%= stylesheet_link_tag :marksmith, "data-turbo-track": "reload" %>
```

2. **Register Stimulus controller:**

```javascript
// app/javascript/controllers/index.js
import { MarksmithController } from "@avo-hq/marksmith"
application.register("marksmith", MarksmithController)
```

3. **Use in forms:**

```erb
<!-- app/views/posts/_form.html.erb -->
<%= marksmith_tag %>
<div class="my-5">
  <%= form.label :content %>
  <%= form.marksmith :content, 
        rows: 10,
        placeholder: "Enter your content...",
        class: ["block shadow-sm rounded-md border px-3 py-2 mt-2 w-full"] %>
</div>
```

4. **Display rendered content:**

```erb
<!-- app/views/posts/show.html.erb -->
<div class="ms:prose ms:prose-slate">
  <%= sanitize(
    marksmithed(post.content),
    attributes: %w(style src class lang),
    tags: %w(table th tr td span) +
    ActionView::Helpers::SanitizeHelper.sanitizer_vendor.safe_list_sanitizer.allowed_tags.to_a) %>
</div>
```

### AI-Enhanced Marksmith Workflows

```ruby
# Generate initial content for Marksmith editor
initial_content = markdown_tool.generate_markdown(
  prompt: "Write a technical blog post about #{topic}",
  style: 'technical',
  length: 'medium'
)

# Create Marksmith field with AI-generated content
field_config = markdown_tool.create_marksmith_field(
  field_name: 'blog_content',
  initial_content: initial_content[:markdown],
  placeholder: 'Continue writing...'
)

# Later, get AI suggestions for improvement
suggestions = markdown_tool.suggest_improvements(
  markdown: user_input,
  focus: 'readability'
)
```

## Batch Processing

```ruby
# Process multiple markdown files
files = Dir.glob("content/*.md")

results = markdown_tool.batch_process(
  files: files,
  operation: 'validate',
  strict: true
)

results[:results].each do |result|
  if result[:error]
    puts "❌ #{result[:file_path]}: #{result[:error]}"
  else
    puts "✅ #{result[:file_path]}: #{result[:result][:issue_count]} issues"
  end
end
```

## Advanced Features

### Complete Workflow Automation

```ruby
# Create a complete markdown workflow
workflow = {
  generate: markdown_tool.generate_markdown(
    prompt: "Ruby on Rails deployment guide",
    style: 'technical',
    length: 'long'
  ),
  edit: nil,
  format: nil,
  validate: nil,
  toc: nil,
  html: nil,
  suggestions: nil
}

# Edit the content
workflow[:edit] = markdown_tool.edit_markdown(
  markdown: workflow[:generate][:markdown],
  instructions: "Add more practical examples and troubleshooting tips"
)

# Format the edited content
workflow[:format] = markdown_tool.format_markdown(
  markdown: workflow[:edit][:edited_markdown],
  style: 'standard',
  line_length: 80
)

# Validate the formatted content
workflow[:validate] = markdown_tool.validate_markdown(
  markdown: workflow[:format][:formatted_markdown],
  strict: true
)

# Generate table of contents
workflow[:toc] = markdown_tool.generate_toc(
  markdown: workflow[:format][:formatted_markdown],
  max_depth: 3,
  style: 'bullet'
)

# Convert to HTML
workflow[:html] = markdown_tool.markdown_to_html(
  markdown: workflow[:format][:formatted_markdown],
  github_style: true,
  syntax_highlighting: true
)

# Get improvement suggestions
workflow[:suggestions] = markdown_tool.suggest_improvements(
  markdown: workflow[:format][:formatted_markdown],
  focus: 'structure'
)
```

## Configuration Options

### Model Selection

```ruby
# Different models for different tasks
markdown_tool.generate_markdown(
  prompt: "Complex technical explanation",
  model: 'gpt-4o'  # More capable model for complex content
)

markdown_tool.edit_markdown(
  markdown: content,
  instructions: "Fix grammar",
  model: 'gpt-4o-mini'  # Faster model for simple edits
)
```

### Style Customization

```ruby
# Available styles
styles = {
  'technical' => 'Technical language with code examples',
  'conversational' => 'Friendly, engaging tone',
  'academic' => 'Formal academic language',
  'creative' => 'Creative and engaging language',
  'professional' => 'Professional business language'
}

# Available lengths
lengths = {
  'short' => '200-300 words',
  'medium' => '500-800 words',
  'long' => '1000-1500 words'
}
```

## API Reference

### Core Methods

#### `generate_markdown(prompt:, style:, length:, model:)`
Generate AI-powered markdown content.

**Parameters:**
- `prompt` (String): The content prompt
- `style` (String): Writing style ('technical', 'conversational', 'academic', 'creative', 'professional')
- `length` (String): Content length ('short', 'medium', 'long')
- `model` (String): AI model to use

**Returns:** Hash with `:markdown`, `:word_count`, `:style`, `:length`, `:model`, `:generated_at`

#### `edit_markdown(markdown:, instructions:, model:, preserve_style:)`
Edit existing markdown content with AI assistance.

**Parameters:**
- `markdown` (String): Original markdown content
- `instructions` (String): Edit instructions
- `model` (String): AI model to use
- `preserve_style` (Boolean): Whether to preserve original style

**Returns:** Hash with `:original_markdown`, `:edited_markdown`, `:changes_summary`, `:word_count_before`, `:word_count_after`

#### `create_template(type:, title:, author:, tags:)`
Create markdown templates for different document types.

**Parameters:**
- `type` (String): Template type ('readme', 'blog_post', 'api_docs', 'article', 'documentation', 'basic')
- `title` (String): Document title
- `author` (String): Author name
- `tags` (Array): Tags for the document

**Returns:** Hash with `:type`, `:title`, `:author`, `:tags`, `:template_markdown`, `:created_at`

#### `validate_markdown(markdown:, strict:)`
Validate markdown syntax and structure.

**Parameters:**
- `markdown` (String): Markdown content to validate
- `strict` (Boolean): Whether to perform strict validation

**Returns:** Hash with `:valid`, `:issues`, `:issue_count`, `:validated_at`

#### `format_markdown(markdown:, style:, line_length:)`
Format and beautify markdown content.

**Parameters:**
- `markdown` (String): Markdown content to format
- `style` (String): Formatting style ('standard', 'compact', 'extended')
- `line_length` (Integer): Maximum line length

**Returns:** Hash with `:original_markdown`, `:formatted_markdown`, `:style`, `:line_length`, `:formatted_at`

#### `generate_toc(markdown:, max_depth:, style:)`
Generate table of contents from markdown headings.

**Parameters:**
- `markdown` (String): Markdown content
- `max_depth` (Integer): Maximum heading depth to include
- `style` (String): TOC style ('bullet', 'numbered', 'links')

**Returns:** Hash with `:toc_markdown`, `:headings_count`, `:max_depth`, `:style`, `:generated_at`

#### `markdown_to_html(markdown:, github_style:, syntax_highlighting:)`
Convert markdown to HTML.

**Parameters:**
- `markdown` (String): Markdown content
- `github_style` (Boolean): Whether to use GitHub-style rendering
- `syntax_highlighting` (Boolean): Whether to enable syntax highlighting

**Returns:** Hash with `:html`, `:github_style`, `:syntax_highlighting`, `:renderer`

#### `suggest_improvements(markdown:, focus:, model:)`
Get AI-powered suggestions for content improvement.

**Parameters:**
- `markdown` (String): Markdown content to analyze
- `focus` (String): Focus area ('readability', 'structure', 'grammar', 'seo', 'accessibility')
- `model` (String): AI model to use

**Returns:** Hash with `:suggestions`, `:focus`, `:model`, `:analyzed_at`

#### `create_marksmith_field(field_name:, initial_content:, placeholder:)`
Create Marksmith-compatible form field configuration.

**Parameters:**
- `field_name` (String): Form field name
- `initial_content` (String): Initial content for the field
- `placeholder` (String): Placeholder text

**Returns:** Hash with `:field_name`, `:initial_content`, `:placeholder`, `:form_helper` or `:fallback_textarea`

#### `batch_process(files:, operation:, **options)`
Process multiple markdown files with the same operation.

**Parameters:**
- `files` (Array): Array of file paths
- `operation` (String): Operation to perform ('format', 'validate', 'generate_toc', 'to_html')
- `**options`: Additional options for the operation

**Returns:** Hash with `:files_processed`, `:successful`, `:failed`, `:results`, `:batch_processed_at`

## Examples

See the `../examples/markdown_example.rb` file for a comprehensive demonstration of all features.

## Error Handling

The MarkdownTool includes comprehensive error handling:

```ruby
begin
  result = markdown_tool.generate_markdown(
    prompt: "Invalid prompt",
    style: 'unknown_style'
  )
rescue Rdawn::Errors::ConfigurationError => e
  puts "Configuration error: #{e.message}"
rescue Rdawn::Errors::TaskExecutionError => e
  puts "Execution error: #{e.message}"
rescue => e
  puts "Unexpected error: #{e.message}"
end
```

## Performance Considerations

- **Model Selection**: Use `gpt-4o-mini` for simple tasks, `gpt-4o` for complex content
- **Batch Processing**: Process multiple files together for efficiency
- **Caching**: Consider caching generated templates and formatted content
- **API Rate Limits**: Be aware of OpenAI API rate limits for high-volume usage

## Cost Optimization

- **Content Generation**: ~$0.001-0.005 per generation
- **Content Editing**: ~$0.001-0.003 per edit
- **Suggestions**: ~$0.001-0.002 per analysis
- **Batch Processing**: More cost-effective than individual operations

## Troubleshooting

### Common Issues

1. **Marksmith not found**: The tool gracefully falls back to basic textarea
2. **Syntax errors**: Check for proper regex escaping in custom patterns
3. **API errors**: Ensure valid OpenAI API key and sufficient credits
4. **Performance issues**: Use appropriate models for task complexity

### Debug Mode

Enable debug mode for detailed logging:

```ruby
markdown_tool = Rdawn::Tools::MarkdownTool.new(
  api_key: ENV['OPENAI_API_KEY'],
  debug: true
)
```

## Contributing

The MarkdownTool is part of the rdawn project. Contributions are welcome for:

- Additional template types
- Enhanced validation rules
- More formatting options
- Better Marksmith integration
- Performance optimizations

## License

The MarkdownTool is part of rdawn and is licensed under the MIT License. 