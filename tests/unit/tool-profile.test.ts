import { describe, expect, it } from 'vitest';
import {
  getEnabledToolNames,
  parseBooleanEnv,
  parseToolProfile,
} from '../../src/tool-profile.js';

describe('tool profile', () => {
  it('defaults to collaboration profile', () => {
    expect(parseToolProfile(undefined)).toBe('collaboration');
    expect(parseToolProfile('')).toBe('collaboration');
  });

  it('rejects unknown profiles', () => {
    expect(() => parseToolProfile('everything')).toThrow(
      'Invalid TRELLO_MCP_TOOL_PROFILE'
    );
  });

  it('keeps restricted tools out of the default collaboration profile', () => {
    const tools = getEnabledToolNames('collaboration', false);

    expect(tools.has('get_card')).toBe(true);
    expect(tools.has('add_comment')).toBe(true);
    expect(tools.has('attach_image_to_card')).toBe(true);
    expect(tools.has('attach_file_to_card')).toBe(true);
    expect(tools.has('attach_data_to_card')).toBe(true);
    expect(tools.has('attach_image_data_to_card')).toBe(true);
    expect(tools.has('download_attachment')).toBe(true);
    expect(tools.has('archive_card')).toBe(false);
    expect(tools.has('perform_system_repair')).toBe(false);
  });

  it('adds setup tools without restricted tools in setup profile', () => {
    const tools = getEnabledToolNames('setup', false);

    expect(tools.has('create_board')).toBe(true);
    expect(tools.has('add_list_to_board')).toBe(true);
    expect(tools.has('archive_card')).toBe(false);
  });

  it('adds restricted tools only when explicitly enabled or using all profile', () => {
    expect(getEnabledToolNames('collaboration', true).has('archive_card')).toBe(true);
    expect(getEnabledToolNames('all', false).has('archive_card')).toBe(true);
  });

  it('parses boolean env values strictly', () => {
    expect(parseBooleanEnv('true')).toBe(true);
    expect(parseBooleanEnv('TRUE')).toBe(true);
    expect(parseBooleanEnv('false')).toBe(false);
    expect(parseBooleanEnv('1')).toBe(false);
    expect(parseBooleanEnv(undefined)).toBe(false);
  });
});
