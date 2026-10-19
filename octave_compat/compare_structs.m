function compare_structs(a, b, prefix)
% Print max abs / relative difference for every numeric leaf of two structs.
  f = fieldnames(a);
  for i = 1:numel(f)
    name = [prefix '.' f{i}];
    if ~isfield(b, f{i}), printf('%-45s missing in second\n', name); continue; end
    x = a.(f{i}); y = b.(f{i});
    if isstruct(x) && isstruct(y)
      compare_structs(x, y, name);
    elseif isnumeric(x) && isnumeric(y)
      if ~isequal(size(x), size(y))
        printf('%-45s size %s vs %s\n', name, mat2str(size(x)), mat2str(size(y)));
      else
        d = max(abs(x(:) - y(:))); s = max(abs(y(:)));
        printf('%-45s size %-9s max|diff| %-10.3g rel %.2g\n', name, mat2str(size(x)), d, d / max(s, eps));
      end
    end
  end
end
