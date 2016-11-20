function plotmesh_fo_grp(D,o,t,woi,foi,type,CL,trans)
% Plot glass mesh brain with MNI coordinates marked
% from source localised SPM MEEG objects
%
% D is a cell array of subjects' D filenames
% o is a optional MNI coords to project [n x 3]     [optional]
% t is trial(s) types [conditions] to include - e.g. 1 or [1 5 6]
%
% woi  is time window of interest                   [optional]
% foi  is freq window of interest                   [optional]
% type is 'evoked' 'induced' or 'trials'            [optional]
% CL   is colour of projected MNI blobs             [optional]
% trans is transparency of overlay                  [optional]
%
% AS2016

% options
%---------------------------------------------------------
dS    = 100; % dot size for functional overlay of trial{t}
s     = 500; % patch size for MNI coordinates

try CL;    catch; CL    = 'r';    end  %[.4 .4 .4];%'r'; % colour of MNI patch
try woi;   catch; woi = [-.1 .3]; end  % time window if interest for source data in trial{t}
try foi;   catch; foi = [];       end  % freq window if interest for source data in trial{t}
try type;  catch; type = 'evoked';end  % 'evoked', 'induced' or 'trial'
try trans; catch; trans= .4;      end


if iscell(D) && ~isobject(D{1}); D = loadarrayspm(D);
elseif ~iscell(D); return;
end

warning off %

% verts & faces for brain
%---------------------------------------------------------
vert  = D{1}.inv{end}.forward(end).mesh.vert;
x     = vert(:,1);
y     = vert(:,2);
z     = vert(:,3);
face  = D{1}.inv{end}.forward(end).mesh.face;

% glass brain
%---------------------------------------------------------
h = patch('faces',face,'vertices',[x(:) y(:) z(:)]);
set(h,'FaceColor',[.4 .4 .4]);
box off;
grid off;
%whitebg(1,'w'); 
camlight('headlight')
%axis tight
set(h,'EdgeColor','none')
material dull
alpha(.2);
lighting phong
set(gca,'visible','off');
set(gcf,'inverthardcopy','off');
hold on;

% fix unspecified parameters
if isempty(woi);   woi   = [0 .3]; end
if isempty(type);  type  = 'evoked'; end
if isempty(trans); trans = .4; end


% call function for projecting into source space
%---------------------------------------------------------
for SUB = 1:length(D)
    if isempty(foi)
        if SUB > 1; fprintf(repmat('\b',[size(str),1])); end
        str = sprintf('Fetching projections for %d of %d datasets\n',SUB,length(D));
        fprintf(str);
    end

    FO        = rebuild(D{SUB},woi,type,foi);
    if isnumeric(t) && length(t) == 1
        % just get this trial / type
        it        = FO.JW{t};
        st(SUB,:) = it;     
    elseif isnumeric(t)
        % get trials of vector 
        it        = spm_cat({FO.JW{t}});
        st(SUB,:) = mean(it,2);
    elseif iscell(t)
        % get indices of this condition[s] name [spm]
        L         = D{1}.condlist;
        fprintf('Averaging projections for %d condition labels\n',length(t));
        for cond = 1:length(t)
            this      = find(strcmp(t{cond},L));
            it        = FO.JW{this};
            if cond == 1
                st(SUB,:) = [mean(it,2)*(1/length(t))];
            else
                st(SUB,:) = [mean(it,2)*(1/length(t))]' + st(SUB,:);
            end
        end
        
    end
end

if ~iscell(st);
    %st = PEig(full(st'));
    mst = mean(st,1);
else
    mst = squeeze(cat(2,st{:}));
    mst = mean(mst,2);
end

%scatter3(x,y,z,[],mst(:),'filled');alpha(.3);

%h = patch('faces',face,'vertices',[x(:) y(:) z(:)],'facevertexcdata',mst(:));%,...

trisurf(face,x,y,z,mst); 
alpha(trans)
set(h,'EdgeColor','interp')
set(h,'FaceVertexCData',mst');
shading interp
camlight headlight
  
% Discard other datasets now:
D = D{1};

if ~isempty(o) % MNIs
    
% find vertices corresponding to provided MNIs
%---------------------------------------------------------
XYZ   = o;
inv   = D.inv{end};
rad   = 1;   

Ns    = size(XYZ, 1); % n points to plot
svert = {};
for i = 1:Ns
    dist = sqrt(sum([vert(:,1) - XYZ(i,1), ...
                     vert(:,2) - XYZ(i,2), ...
                     vert(:,3) - XYZ(i,3)].^2, 2));
    if rad > 0
        for j = 1:rad
            [junk,svert{i,j}] = min(dist);
            dist(svert{i,j}) = NaN;
        end
    else
        [junk,svert{i}] = min(dist);
        XYZ(i, :) = vert(svert{i}, :);
    end
end

% add selected points to plot
%---------------------------------------------------------
for i = 1:Ns
    for j = 1:size(svert,2)
        scatter3(vert(svert{i,j},1),...
                 vert(svert{i,j},2),...
                 vert(svert{i,j},3),...
                 s,CL,'filled');
                    alpha(trans)
    end
end

end




% MNI=[-46 20 8;
%  -61 -32 8;
%  -42 -14 7; %-22
%   46 20 8;
%   59 -25 8;
%   46 -14 8];





